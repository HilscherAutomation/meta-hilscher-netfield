#
# SPDX-License-Identifier: MIT
#

CYCLONEDX_BOM_COMPONENT_NAME ??= "${DISTRO_NAME}"
CYCLONEDX_BOM_COMPONENT_VERSION ??= "${FIRMWARE_VERSION}"

CYCLONEDX_SSTATEDIR = "${WORKDIR}/cyclonedx"
DEPLOY_DIR_CYCLONEDX ??= "${DEPLOY_DIR}/cyclonedx"

# The product name that the CVE database uses.  Defaults to BPN, but may need to
# be overriden per recipe (for example tiff.bb sets CVE_PRODUCT=libtiff).
CVE_PRODUCT ??= "${BPN}"
CVE_VERSION ??= "${PV}"

python do_create_component_sbom() {
    import json
    import oe.cve_check
    from pathlib import Path

    # Create the component SBOM
    name = d.getVar("CVE_PRODUCT")
    version = d.getVar("CVE_VERSION")

    component = []
    patches = []

    # Extract all downloaded sources
    def add_vcs_uris(d, entry):
        added_urls = set()
        fetch = bb.fetch2.Fetch((d.getVar('SRC_URI') or '').split(), d)
        for url in fetch.urls:
            type = bb.fetch2.decodeurl(url)[0]
            if type not in ['file', 'crate']:
                scheme = bb.fetch2.decodeurl(url)[0]
                network_loc = bb.fetch2.decodeurl(url)[1]
                path = bb.fetch2.decodeurl(url)[2]

                params = bb.fetch2.decodeurl(url)[5]
                if 'protocol' in params:
                    scheme = scheme + '+' + params['protocol']
                upstream_url = scheme + "://" + network_loc + path

                name = params.get('name', '')

                sha256_search_vars = []

                urldata = fetch.ud[url]
                if hasattr(urldata, 'sha256_expected') and urldata.sha256_expected is not None:
                    sha256 = urldata.sha256_expected
                elif hasattr(urldata, 'revisions') and urldata.revisions is not None:
                    if name != '':
                        sha256 = urldata.revisions[name]
                    else:
                        sha256 = urldata.revisions["default"]
                else:
                    bb.fatal(f"Unable to extract SHA256 for {url}")

                if upstream_url not in added_urls:
                    added_urls.add(upstream_url)

                    vcs_entry = {
                        "type": "vcs",
                        "url": upstream_url,
                        "hashes": [
                            {
                                "alg": "SHA-256",
                                "content": sha256,
                            }
                        ]
                    }
                    entry["externalReferences"].append(vcs_entry)

    # Get all patched CVEs including URL/content
    def get_cve_patches(d):
        import oe.patch
        import re

        ret = []

        cve_match = re.compile(r"CVE:( CVE-\d{4}-\d+)+")
        cve_file_name_match = re.compile(r".*(CVE-\d{4}-\d+)", re.IGNORECASE)

        patches = oe.patch.src_patches(d)
        for url in patches:
            patch_text = None
            patched_cves = set()

            patch_file = bb.fetch.decodeurl(url)[2]

            # Check patch file name for CVE ID
            fname_match = cve_file_name_match.search(patch_file)
            if fname_match:
                cve = fname_match.group(1).upper()
                bb.debug(2, "Found %s from patch file name %s" % (cve, patch_file))
                patched_cves.add(cve)

            if os.path.isfile(patch_file):
                # Check content
                with open(patch_file, "r", encoding="utf-8") as f:
                    try:
                        patch_text = f.read()
                    except UnicodeDecodeError:
                        bb.debug(1, "Failed to read patch %s using UTF-8 encoding"
                                " trying with iso8859-1" %  patch_file)
                        f.close()
                        with open(patch_file, "r", encoding="iso8859-1") as f:
                            patch_text = f.read()

                # Search for one or more "CVE: " lines
                for match in cve_match.finditer(patch_text):
                    # Get only the CVEs without the "CVE: " tag
                    cves = patch_text[match.start()+5:match.end()]
                    for cve in cves.split():
                        if cve not in patched_cves:
                            bb.debug(2, "Patch %s solves %s" % (patch_file, cve))
                            patched_cves.add(cve)

            for patched_cve in patched_cves:
                patch_entry = {
                    "type" : "backport",
                    "resolves" : [
                        { "type" : "security",
                          "id" : patched_cve,
                          "source" : {
                              "name" : "NVD",
                              "url" : f"https://nvd.nist.gov/vuln/detail/{patched_cve}"
                          }
                        }
                    ]
                }
                if os.path.isfile(patch_file):
                    patch_entry["diff"] = { "text": { "content": patch_text }}
                else:
                    patch_entry["diff"] = { "url": patch_file }

                ret.append(patch_entry)

        return ret

    # update it with the new package info
    names = name.split()
    for index, cpe in enumerate(oe.cve_check.get_cpe_ids(name, version)):
        # Create basic entry
        bb.debug(2, f"Creating component entry for {name}@{version} ({cpe})")
        entry = {
            "name": names[index],
            "version": version,
            "cpe": cpe,
            "type" : 'library' if d.getVar('SECTION') == 'libs' else 'application',
            "licenses" : [{
                "expression" : d.getVar('LICENSE').replace(' & ', ' AND ').replace(' | ', ' OR '),
            }],
            "externalReferences": [
                {
                    "url": d.getVar('HOMEPAGE'),
                    "type": "website"
                },
            ],
        }

        add_vcs_uris(d, entry)

        # Add list of backported vulnerability fixes
        patches = get_cve_patches(d)
        if len(patches) > 0:
            entry['pedigree'] = {}
            entry['pedigree']['patches'] = []

        for patch in patches:
            entry['pedigree']['patches'].append(patch)

        component.append(entry);

    bb.debug(2, f"Component ${component}")

    dest = Path(os.path.join(d.getVar('CYCLONEDX_SSTATEDIR'), d.getVar('PN')))
    if d.getVar('PACKAGE_ARCH') == d.getVar('MACHINE_ARCH'):
        dest = dest / d.getVar('MACHINE_ARCH')
    dest = dest / (d.getVar('PN') + '.sbom.json')
    dest.parent.mkdir(exist_ok=True, parents=True)
    with dest.open("w") as f:
        f.write(json.dumps(component, indent=4))
}

SSTATETASKS += "do_create_component_sbom"
do_create_component_sbom[sstate-inputdirs] = "${CYCLONEDX_SSTATEDIR}"
do_create_component_sbom[sstate-outputdirs] = "${DEPLOY_DIR_CYCLONEDX}"

python do_create_component_sbom_setscene () {
    sstate_setscene(d)
}
addtask do_create_component_sbom_setscene

addtask create_component_sbom after do_fetch before do_build
do_create_component_sbom[dirs] = "${CYCLONEDX_SSTATEDIR}/${PN}"
do_create_component_sbom[cleandirs] = "${CYCLONEDX_SSTATEDIR}"
do_create_component_sbom[depends] += "${PATCHDEPENDENCY}"
do_create_component_sbom[deptask] = "do_create_component_sbom"

python do_create_image_sbom() {
    import json
    import oe.packagedata
    import os
    import uuid
    from datetime import datetime
    from pathlib import Path
    from oe.rootfs import image_list_installed_packages

    image_name = d.getVar("IMAGE_NAME")
    image_link_name = d.getVar("IMAGE_LINK_NAME")
    imgdeploydir = Path(d.getVar("IMGDEPLOYDIR"))
    packages = image_list_installed_packages(d)

    sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.4",
        "serialNumber": "urn:uuid:" + str(uuid.uuid4()),
        "version": 1,
        "metadata": {
            "timestamp": datetime.now().isoformat(),
            "component": {
                "type": "operating-system",
                "name": d.getVar('CYCLONEDX_BOM_COMPONENT_NAME'),
                "version": d.getVar('CYCLONEDX_BOM_COMPONENT_VERSION'),
                "properties": [
                    {
                        "name": "machine",
                        "value": d.getVar('MACHINE'),
                    }
                ]
            }
        },
        "components": []
    }

    # Find installed recipes via package names
    installed_recipes = []
    for pkg in sorted(packages.keys()):
        pkg_info = os.path.join(d.getVar('PKGDATA_DIR'),
                                'runtime-reverse', pkg)
        pkg_dic = oe.packagedata.read_pkgdatafile(pkg_info)

        recipe_name = pkg_dic['PN']
        if recipe_name in installed_recipes:
            bb.debug(2, f"Skipping already found recipe {recipe_name} for package {pkg}")
        else:
            installed_recipes.append(recipe_name)

    # Add installed recipes/components
    for recipe in installed_recipes:
        comp_sbom = Path(os.path.join(d.getVar('DEPLOY_DIR_CYCLONEDX'),
                                      recipe, d.getVar('MACHINE_ARCH'),
                                      recipe + '.sbom.json'))
        if not comp_sbom.is_file():
            comp_sbom = Path(os.path.join(d.getVar('DEPLOY_DIR_CYCLONEDX'),
                                      recipe, recipe + '.sbom.json'))

        with comp_sbom.open("r") as f:
            comp = json.loads(f.read())
            # component SBOM contains array of possible component names,
            # so covert it for final SBOM
            for tmp in comp:
                sbom['components'].append(tmp)

    # Write final SBOM
    image_sbom = Path(os.path.join(imgdeploydir,
                                   image_name + '.sbom.json'))
    with image_sbom.open("w") as f:
        f.write(json.dumps(sbom, indent=4))

    image_sbom_link = Path(os.path.join(imgdeploydir,
                                        image_link_name + '.sbom.json'))

    image_sbom_link.symlink_to(image_name + '.sbom.json')
}

do_rootfs[recrdeptask] += "do_create_component_sbom"

ROOTFS_POSTUNINSTALL_COMMAND =+ "do_create_image_sbom;"
