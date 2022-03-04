============
OEM-Branding
============

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Since Hilscher is an **O**\riginal **E**\quipment **M**\anufacturer (OEM) supplying the |project_name| to various vendors,
the design of the build environment is already prepared to create so called branded images.
To achieve this, the original |project_name| image is divided into two squashfs images.
The first image called OEM-base-image (*netfield-oem-image*) consists of common applications and configurations
whereas the second one contains vendor-specific adjustments and maybe some supplemnents.
When mounting the second vendor specific image on top of the OEM-base-image,
it looks like the previously known |project_name| image (*netfield-image*).
For read-/writeable storage locations within the read-only RootFS,
additional overlays can now be mounted on top of this merged image.

All recipes and classes needed to create branded |project_name| versions are grouped in the separate yocto layer *meta-oem*,
which is in turn located in the *meta-hilscher-netfield*.

The components involved are described below.

.. contents::
   :local:
   :backlinks: top
   :depth: 1

meta-oem/classes/hilscher-oem-image.bbclass
===========================================

All vendor-specific overlay images recipes must inherit this bbclass in order to make use of the following properties.

- Required variables to build vendor-specific OEM images.

  ``OEM_BASE_IMAGE``
     Because a vendor-specific overlay image based on an OEM-base-image, it is required to define this in use of the variable ``OEM_BASE_IMAGE``.
     The OEM-base-image will also be included into the WIC and the SWU image files.

     .. code-block::
        :caption: Example: meta-hilscher-netfield/meta-oem/recipes-core/images/netfield-image-oem-default-ovl.bb

        OEM_BASE_IMAGE="netfield-image-oem"

  ``OEM_BRANDING_MERGE``
     Set this varibale to 1, if a single merged SWU image file is desired, containing all versions of vendor-specific overlay images.

     .. code-block::
        :caption: Example: meta-hilscher-netfield/meta-oem/recipes-core/images/netfield-image-oem-all.bb

        OEM_BRANDING_MERGE="1"

  ``OEM_BRANDING_IMAGES``
     This space separated list defines images that can be created by a special image recipe
     capable of creating multiple vendor-specific overlay images (e.g. *netfield-image-oem-all.bb*).

     .. code-block::
        :caption: Example: meta-hilscher-netfield-imx8/conf/machine/netfield-iolink-edge-gw-rev2

        OEM_BRANDING_IMAGES = "hilscher-netfield-image-oem-netfield hilscher-netfield-image-oem-sensoredge"

     .. Note::
        All images must based on the same OEM-base-image.

  ``OEM_IMAGE_INSTALL``
     Packages to be installed into vendor-specific overlay images must be defined by adding them to the ``OEM_IMAGE_INSTALL`` variable.

     .. code-block::
        :caption: Example: meta-hilscher-netfield/meta-oem/recipes-core/images/netfield-image-oem-default-ovl.bb

        OEM_IMAGE_INSTALL = " \
            login-welcome \
            os-release \
            nginx-conf \
            upnpd-conf \
            upnpd-oem-${VENDOR_ID} \
        "

     .. Note::
        The well-known yocto variable ``PACKAGE_INSTALL`` will be replaced by ``OEM_IMAGE_INSTALL``!

        .. code-block::

           PACKAGE_INSTALL = "${OEM_IMAGE_INSTALL}"

- Since all images created by the yocto build system contains some additional files and directories by default,
  a vendor-specific overlay image will also contains this unwanted material.
  To solve this, an empty image, including the same unwanted stuff, is created as a so called subtraction image.
  This image is now subtracted from the vendor-specific overlay image thus the vendor-specific overlay image will remain only.

  .. code-block::

     (vendor-specific-oem-image + x) - (empty-image + x) = vendor-specific-oem-image

  .. collapse:: Example: Filesystem structure of involved and resulted images

     .. csv-table::
        :header: vendor-specific-oem-image + x, \\-, empty-image + x, =, vendor-specific-oem-image

        "::

           /
           ├── etc
           │   ├── default
           │   │   └── postinst
           │   ├── nginx
           │   │   └── nginx.conf
           │   ├── os-release -> ../usr/lib/os-release
           │   ├── ld.so.cache
           │   └── version
           ├── opt
           │   └── upnpd
           │       ├── desc
           │       │   └── logo.png
           │       └── netiotdevicedesc.xml
           ├── run
           ├── usr
           │   ├── lib
           │   │   ├── issue
           │   │   └── os-release
           │   └── share
           │       └── common-licenses
           │           ├── login-welcome
           │           │   └── recipeinfo
           │           ├── nginx-conf
           │           │   ├── generic_BSD-2-Clause -> ../generic_BSD-2-Clause
           │           │   ├── LICENSE
           │           │   └── recipeinfo
           │           ├── os-release
           │           │   ├── generic_MIT -> ../generic_MIT
           │           │   └── recipeinfo
           │           ├── upnpd-conf
           │           │   └── recipeinfo
           │           ├── upnpd-oem-hilscher
           │           │   └── recipeinfo
           │           ├── generic_BSD-2-Clause
           │           ├── generic_MIT
           │           └── license.manifest
           ├── var
           │   ├── cache
           │   │   ├── ldconfig
           │   │   │   └── aux-cache
           │   │   └── opkg
           │   └── lib
           │       └── opkg
           ├── firmware.image_name
           ├── firmware.manifest
           ├── firmware.vendor_id
           ├── firmware.vendor_image_name
           └── firmware.version
        ", **\-**,"::

           /
           ├── etc
           │   ├── default
           │   │   └── postinst
           │   ├
           │   │
           │   ├
           │   ├── ld.so.cache
           │   └── version
           ├
           │
           │
           │
           │
           ├── run
           ├── usr
           │   ├
           │   │
           │   │
           │   └── share
           │       └── common-licenses
           │           ├
           │           │
           │           ├
           │           │
           │           │
           │           │
           │           ├
           │           │
           │           │
           │           ├
           │           │
           │           ├
           │           │
           │           ├
           │           ├
           │           └── license.manifest
           ├── var
           │   ├── cache
           │   │   ├── ldconfig
           │   │   │   └── aux-cache
           │   │   └── opkg
           │   └── lib
           │       └── opkg
           ├── firmware.image_name
           ├── firmware.manifest
           ├
           ├
           └── firmware.version
        ", **=**,"::

           /
           ├── etc
           │   ├
           │   │
           │   ├── nginx
           │   │   └── nginx.conf
           │   ├── os-release -> ../usr/lib/os-release
           │   ├
           │   └
           ├── opt
           │   └── upnpd
           │       ├── desc
           │       │   └── logo.png
           │       └── netiotdevicedesc.xml
           ├
           ├── usr
           │   ├── lib
           │   │   ├── issue
           │   │   └── os-release
           │   └── share
           │       └── common-licenses
           │           ├── login-welcome
           │           │   └── recipeinfo
           │           ├── nginx-conf
           │           │   ├── generic_BSD-2-Clause -> ../generic_BSD-2-Clause
           │           │   ├── LICENSE
           │           │   └── recipeinfo
           │           ├── os-release
           │           │   ├── generic_MIT -> ../generic_MIT
           │           │   └── recipeinfo
           │           ├── upnpd-conf
           │           │   └── recipeinfo
           │           ├── upnpd-oem-hilscher
           │           │   └── recipeinfo
           │           ├── generic_BSD-2-Clause
           │           ├── generic_MIT
           │           └
           ├
           │
           │
           │
           │
           │
           │
           ├
           ├
           ├── firmware.vendor_id
           ├── firmware.vendor_image_name
           └
        "

  .. Note::
     This is one of the main goal of this bbclass and is performed in the task function *do_cleanup()* after *do_rootfs()* and before *do_image_qa()*.

     .. code-block::

        addtask do_cleanup after do_rootfs before do_image_qa

- As the OEM branding support has the capability to create more than one image per platform,
  for example a *netfield* and a *sensoredge* version, a new function is required to map these into the SWU update files.
  This new function overwrites the IMAGE_CMD_swu() function defined in *hilscher_image_types.bbclass*
  and covers the amount of images as well as the additional vendor-specific overlay images.

  .. collapse:: Example: sw-description file

     .. code-block::
        :linenos:
        :caption: Example of sw-description file consisting two vendor-specific OEM overlay images, the netfield- and the sensoredge-version
        :emphasize-lines: 41-43,85-87

        software :
        {
          version = "2.4.0.0.debug.nightly-17";
          netfield-iolink-edge-gw :
          {
            oem :
            {
              hilscher-netfield-image-oem-netfield :
              {
                hardware-compatibility = [ "2" ];
                files = (
                  {
                    filename = "boot.bin";
                    sha256 = "bc02089ba3ca520fa10b4825e21d737c5150f8bcdfb58e33a3e3041d23c2ef63";
                    path = "/dev/mmcblk0";
                    offset = "33K";
                    name = "boot.bin";
                    version = "bc02089ba3ca520fa10b4825e21d737c5150f8bcdfb58e33a3e3041d23c2ef63";
                    install-if-different = "1";
                  },
                  {
                    filename = "boot1.bin";
                    sha256 = "bc02089ba3ca520fa10b4825e21d737c5150f8bcdfb58e33a3e3041d23c2ef63";
                    path = "/dev/mmcblk1";
                    offset = "33K";
                    name = "boot.bin";
                    version = "bc02089ba3ca520fa10b4825e21d737c5150f8bcdfb58e33a3e3041d23c2ef63";
                    install-if-different = "1";
                  },
                  {
                    filename = "boot.squashfs";
                    sha256 = "61104c98331a826dc27c79a78793a18c2a92bb4cf20ee878a843f4b213034021";
                    path = "/dev/null";
                  },
                  {
                    filename = "system.squashfs";
                    sha256 = "ee159d5d8e1a2a9535f2725e7fadeadd619c3da6011855df0bcd7e10014e6f82";
                    path = "/dev/null";
                  },
                  {
                    filename = "hilscher-netfield-image-oem-netfield-netfield-iolink-edge-gw-rev2.data-oem.squashfs";
                    sha256 = "022679d594a2347970885f4a01af5e4a9ca8f2c2459ae3dd38b896ca6240ce84";
                    path = "/dev/null";
                  } );
                scripts = (
                  {
                    filename = "helper.lua";
                    sha256 = "f2959b00a683bde3d577484c04d3ca815aaeb8d9f4ba075f43ad88381f66d180";
                    type = "lua";
                  } );
              };
              hilscher-netfield-image-oem-sensoredge :
              {
                hardware-compatibility = [ "2" ];
                files = (
                  {
                    filename = "boot.bin";
                    sha256 = "bc02089ba3ca520fa10b4825e21d737c5150f8bcdfb58e33a3e3041d23c2ef63";
                    path = "/dev/mmcblk0";
                    offset = "33K";
                    name = "boot.bin";
                    version = "bc02089ba3ca520fa10b4825e21d737c5150f8bcdfb58e33a3e3041d23c2ef63";
                    install-if-different = "1";
                  },
                  {
                    filename = "boot1.bin";
                    sha256 = "bc02089ba3ca520fa10b4825e21d737c5150f8bcdfb58e33a3e3041d23c2ef63";
                    path = "/dev/mmcblk1";
                    offset = "33K";
                    name = "boot.bin";
                    version = "bc02089ba3ca520fa10b4825e21d737c5150f8bcdfb58e33a3e3041d23c2ef63";
                    install-if-different = "1";
                  },
                  {
                    filename = "boot.squashfs";
                    sha256 = "61104c98331a826dc27c79a78793a18c2a92bb4cf20ee878a843f4b213034021";
                    path = "/dev/null";
                  },
                  {
                    filename = "system.squashfs";
                    sha256 = "ee159d5d8e1a2a9535f2725e7fadeadd619c3da6011855df0bcd7e10014e6f82";
                    path = "/dev/null";
                  },
                  {
                    filename = "hilscher-netfield-image-oem-sensoredge-netfield-iolink-edge-gw-rev2.data-oem.squashfs";
                    sha256 = "ffac38c88d9a5452d611da073106271c9cc7f5585362e89a6bd6425e838c3a5f";
                    path = "/dev/null";
                  } );
                scripts = (
                  {
                    filename = "helper.lua";
                    sha256 = "f2959b00a683bde3d577484c04d3ca815aaeb8d9f4ba075f43ad88381f66d180";
                    type = "lua";
                  } );
              };
            };
          };
        };


meta-oem/recipes-core/images/empty-image.bb
===========================================

This recipe creates an empty image which only contains unwanted stuff added by the yocto build system.
Its used as a subtractor image by the *hilscher-oem-image.bbclass*.

meta-oem/recipes-core/images/netfield-image-oem.bb
==================================================

This recipe is based on the recipes-core/images/netfield-image.bb recipe and represents the OEM-base-image.

Essential modifications to prepare the image as an OEM image are  ...
   - Define the variables as followed ...

      .. code-block:: bash
         :caption: Example: meta-oem/recipes-core/images/oem-base.inc

         VENDOR_NAME ??= "TBD-by-OEM"
         VENDOR_URL ??= "TBD-by-OEM"

         VENDOR_DEVICE_NAME ??= "TBD-by-OEM"
         VENDOR_DEVICE_DESC ??= "TBD-by-OEM"
         VENDOR_DEVICE_REV ?= "TBD-by-OEM"
         VENDOR_DEVICE_URL ??= "TBD-by-OEM"

         VENDOR_UPNP_DEVICE_TYPE ??= "TBD-by-OEM"

         VENDOR_OS_ID ??= "TBD-by-OEM"
         VENDOR_OS_NAME ??= "TBD-by-OEM"

         # NOTE: Currently unused
         VENDOR_OUI ??= "TBD-by-OEM"
         VENDOR_DEVICE_PN ??= "TBD-by-OEM"

   - By calling the function do_oem_base_definitions(), these variable are patched into the appropriated packages.

      .. code-block::

         ROOTFS_POSTUNINSTALL_COMMAND_append += " do_oem_base_definitions ;"


meta-oem/recipes-core/images/<vendor>-netfield-image-oem-<version>.bb
=====================================================================

This is the fixed naming scheme for vendor-specific overlay image recipes related to a |project_name| OEM-base-image (*netfield-image-oem.bb*).

Example: *hilscher-netfield-image-oem-sensoredge.bb*

Essential steps are  ...
   - Inherit the *hilscher-oem-image.bbclass*.
   - Variables, predefined by the OEM-base-image, must be reconfigured and patched according to the vendor specifications.
   
      .. code-block:: bash
         :caption: Example: meta-oem/recipes-core/images/hilscher-netfield-image-oem-sensoredge.bb
        
         VENDOR_NAME = "Hilscher Gesellschaft fuer Systemautomation mbH"
         VENDOR_URL = "http://www.hilscher.com"
         
         VENDOR_DEVICE_NAME = "netIOT Edge Gateway"
         VENDOR_DEVICE_DESC = "netIOT Edge Gateway"
         VENDOR_DEVICE_REV = "1.0"
         VENDOR_DEVICE_URL = "TBD"
         
         VENDOR_UPNP_DEVICE_TYPE = "TBD"
         
         VENDOR_OS_ID = "netfield"
         VENDOR_OS_NAME = "netFIELD OS"
         
         # NOTE: Currently unused
         VENDOR_OUI = "TBD"
         VENDOR_DEVICE_PN = "TBD"
         
   - Packages to be install must be added to the ``OEM_IMAGE_INSTALL`` variable.


meta-oem/recipes-core/images/netfield-image-oem-all.bb
======================================================

This recipe iterates over the ``OEM_BRANDING_IMAGES`` variable and creates each vendor-specific overlay image listed,
as well as a common merged SWU image that provides a single file for updating devices running different vendor versions.

.. Note::
   This image recipe can be used to build all available vendor-specific |project_name| OEM version in a single build job!
