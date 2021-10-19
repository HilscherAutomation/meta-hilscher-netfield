BRANCH ??= "develop"

SRC_URI="git://bitbucket.hilscher.com/scm/ial/cockpit-netiot.git;user=${HILSCHER_BITBUCKET_USER};protocol=https;branch=${BRANCH}"
SRCREV = "${AUTOREV}"
PV = "dev-${@d.getVar('BRANCH').replace("/", "-")}+git${SRCPV}"

LIC_FILES_CHKSUM="file://COPYING;md5=4fbd65380cdd255951079008b364516c"

S="${WORKDIR}/git"

EXTRA_OECONF_append += "${@bb.utils.contains("IMAGE_FEATURES", "debug-tweaks", "--enable-debug", "" ,d)}"

do_configure_prepend() {
  export HOME="${WORKDIR}"

  username=$(echo ${HILSCHER_BITBUCKET_USER} | cut -d ":" -f1)
  password=$(echo ${HILSCHER_BITBUCKET_USER} | cut -d ":" -f2)
  echo "machine bitbucket.hilscher.com login $username password $password" > $HOME/.netrc

  git submodule init
  git submodule update --recursive

  node ${S}/dev-scripts/yarn-1.21.1.js install --offline --frozen-lockfile
}

require cockpit.inc
CVE_VERSION="194"

# Don't select this per default
DEFAULT_PREFERENCE = "-1"
