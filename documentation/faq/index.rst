===
FAQ
===

.. toctree::
   :maxdepth: 1

.. only::  subproject and html

General
=======

Build using Jenkins
-------------------

Build requires at least the following credentials being provied by Jenkins:

+-------------------------+-------------------------------------------------------------+
| Id                      | Description                                                 |
+=========================+=============================================================+
| ``hilscher-scmreader``  | Domain-User SCMReader which is allowed to read repositories |
+-------------------------+-------------------------------------------------------------+
| ``hilscher-scmbuilder`` | Domain-User SCMBuilder with write access to nexus           |
+-------------------------+-------------------------------------------------------------+

Jenkins must also provider a configuration file (id must be provided in build parameters)

.. code-block::
   :caption: site.conf

   SSTATE_MIRRORS = "file://.* file:///opt/shared/yocto/sstate-cache/netiot/${DISTRO_VERSION}/PATH \
                     file://.* http://nxybuilder01/sstate-cache/netiot/${DISTRO_VERSION}/PATH \
                     file://.* http://nxybuilder01.hilscher.local/sstate-cache/netiot/${DISTRO_VERSION}/PATH"

   # Try tarballs from own local mirror
   SOURCE_MIRROR_URL = "http://nxybuilder01/sources-mirror/"
   INHERIT += "own-mirrors"

   # Hilscher SVN / git access data
   HILSCHER_SVN_BASEURL = "192.168.100.17"
   HILSCHER_SVN_USER = "<svn user>"
   HILSCHER_SVN_PSWD = "<svn password>"
   HILSCHER_BITBUCKET_USER = "<bitbucket user>:<bitbucket password>"

   # Signing key mappings
   # Always use PKCS11-Proxy
   SIGN_WRAPPER_MODE="pkcs11"
   SIGN_WRAPPER_PKCS11_REMOTE="tcp://nxybuilder01.hilscher.local:5657"
   SIGN_WRAPPER_PKCS11_PIN="1234"

   PLATFORM_KEYNAME="${MACHINE}"
   SIGN_WRAPPER_KEY_SRC = "${@d.getVar('SIGN_WRAPPER_KEY_SRC' + '_' + d.getVar('MACHINE', True), True)}"

   # Intel
   SIGN_WRAPPER_KEY_SRC_niot-e-tijcx-gb ?= "pkcs11:token=netFIELDOS;object=niot-e-tijcx-gb-release_DB"
   SIGN_WRAPPER_KEY_SRC_niot-e-tib100   ?= "pkcs11:token=netFIELDOS;object=niot-e-tib100-release_DB"
   SIGN_WRAPPER_KEY_SRC_niot-e-vm-en    ?= "pkcs11:token=netFIELDOS;object=niot-e-vm-en-release_DB"

   # RPI3
   SIGN_WRAPPER_KEY_SRC_niot-e-tpi51-en-re   ?= "pkcs11:token=netFIELDOS;object=niot-e-tpi51-en-re-release"
   SIGN_WRAPPER_KEY_SRC_niot-e-npi3-51-en-re ?= "pkcs11:token=netFIELDOS;object=niot-e-npi3-51-en-re-release"
   SIGN_WRAPPER_KEY_SRC_niot-e-npi3-en       ?= "pkcs11:token=netFIELDOS;object=niot-e-npi3-en-release"

   # i.MX8
   SIGN_WRAPPER_KEY_SRC_netfield-iolink-edge-gw-rev1 ?= "pkcs11:token=netFIELDOS;object=sensorEDGE-release"
   SIGN_WRAPPER_KEY_SRC_netfield-iolink-edge-gw-rev2 ?= "pkcs11:token=netFIELDOS;object=sensorEDGE-release"
   SIGN_WRAPPER_KEY_SRC_niot-e-nfl90-q2n16-n-rev1    ?= "pkcs11:token=netFIELDOS;object=sensorEDGE-release"
   SIGN_WRAPPER_KEY_SRC_netfield-compact-x8m-rev1    ?= "pkcs11:token=netFIELDOS;object=netfield-compact-x8m-release"

   HAB_CSF_KEY="pkcs11:token=netfield-compact-x8m-release;object=CSF1_1;type=cert;pin-value=${SIGN_WRAPPER_PKCS11_PIN}"
   HAB_IMG_KEY="pkcs11:token=netfield-compact-x8m-release;object=IMG1_1;type=cert;pin-value=${SIGN_WRAPPER_PKCS11_PIN}"

Following parameters are available:

+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| Name                            | Type        | Default         | Description                                                                            |
+=================================+=============+=================+========================================================================================+
| ``sync_default_parameters``     | Boolean     | false           | Synchronize project parameters and abort build                                         |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``site_conf``                   | Config File |                 | Build parameters to use                                                                |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``platforms``                   | String      | <all platforms> | Space separated list of blatforms to build                                             |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``enable_debug_features``       | Boolean     | false           | Build debug images                                                                     |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``netfield_branch``             | String      | <from manifest> | Branch of meta-hilscher-netfield to build                                              |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``netfield_intel_branch``       | String      | <from manifest> | Branch of meta-hilscher-netfield-intel to build                                        |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``netfield_raspberrypi_branch`` | String      | <from manifest> | Branch of meta-hilscher-netfield-raspberrypi to build                                  |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``netfield_imx8_branch``        | String      | <from manifest> | Branch of meta-hilscher-netfield-imx8 to build                                         |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``enable_cockpit_dev``          | Boolean     | false           | Build a development version of cockpit/DeviceManager                                   |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``cockpit_branch``              | String      | develop         | Branch of cockpit/DeviceManager to build if enable_cockpit_dev is set                  |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``fw_version``                  | String      | "2.4.0.0"       | Firmware version                                                                       |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``fw_suffix``                   | String      | ""              | Firmware suffix                                                                        |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``enable_archive``              | Boolean     | false           | Publish artifacts                                                                      |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``enable_repo_notifications``   | Boolean     | false           | Publish build status of layers                                                         |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``mail_notification``           | Choice      | always          | Choose a method when mail notifications should be send. ("always" or "failured-fixed") |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``mail_recipients``             | String      |                 | List of e-Mail addresses for sending build status                                      |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``enable_cve_checks``           | Boolean     | false           | Perform a CVE check on all packages / images. (Requires WarningsNG)                    |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``enable_unittests``            | Boolean     | false           | Run unit-tests (needs IP address of testdevice).                                       |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+
| ``cleanws``                     | Choice      | always          | Choose a method for cleaning up the workspace ("always", "onSucess", "never")          |
+---------------------------------+-------------+-----------------+----------------------------------------------------------------------------------------+

Device / hardware handling
==========================

How to recover a bricked / first-time setup a device
----------------------------------------------------

To recover a bricked device or for first-time installation a wic image can be deployed,
which is a hard disk image that can be written to a SD/MMC card directly by using one of the following tools

* Win32DiskImager (https://sourceforge.net/projects/win32diskimager/)
* BalenaEtcher (https://www.balena.io/etcher/)
* dd

  .. code::

     bzcat image.wic.bz2 | dd of=/dev/sdb

Recover a bricked devices that have no USB port or no access to SD/MMC Card (e.g. sensorEDGE)
---------------------------------------------------------------------------------------------

.. note: This requires at least a working bootloader on the device

**Device with magnetic switch**

Enter a rescue mode as follows:

* Power-Down device
* Hold a magnet near the magnetic contact
* Power-Up device

**Device with serial console**

 * Select Fastboot mode from menu

For recovery process see :ref:`implementations/bootloader/fastboot:fastboot`

Resize data partition
---------------------

Per default the data partition is 60% of the remaining size of the data area of the disk.
40% is reserved for backup purposes. It is recommended to keep the backup partition with
at least 640MB, so it can be used for operating system updates. LVM Partition size might
need to be larger, as the resulting filesystem is smaller and must be 640MB in size.

If resulting partition becomes smaller than 640MB the data partition will be used for updates
instead and you need to make sure enough space is left, otherwise updates will fail.

.. note:: Shrinking the data partition size again is not supported and a recovery is required instead.

Resizing is done as follows:

.. code ::

   $ sudo umount /mnt/backup
   $ sudo e2fsck -f /dev/mapper/data-backup
   $ sudo resize2fs -p /dev/mapper/data-backup 1G
   $ sudo lvreduce -L 1G /dev/mapper/data-backup
   $ sudo mount /dev/mapper/data-backup /mnt/backup
   $ sudo lvextend -l +100%FREE /dev/mapper/data-data
   $ sudo resize2fs -p /dev/mapper/data-data


.. collapse:: Example output

   .. code-block::

      $ sudo umount /mnt/backup
      $ sudo e2fsck -f /dev/mapper/data-backup
      e2fsck 1.45.4 (23-Sep-2019)
      Pass 1: Checking inodes, blocks, and sizes
      Pass 2: Checking directory structure
      Pass 3: Checking directory connectivity
      Pass 4: Checking reference counts
      Pass 5: Checking group summary information
      backup: 16/2711552 files (0.0% non-contiguous), 248053/10834944 blocks
      $ sudo resize2fs -p /dev/mapper/data-backup 1G
      resize2fs 1.45.4 (23-Sep-2019)
      Resizing the filesystem on /dev/mapper/data-backup to 262144 (4k) blocks.
      Begin pass 2 (max = 65541)
      Relocating blocks             XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      Begin pass 3 (max = 331)
      Scanning inode table          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      Begin pass 4 (max = 9)
      Updating inode references     XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      The filesystem on /dev/mapper/data-backup is now 262144 (4k) blocks long.

      $ sudo lvreduce -L 1G /dev/mapper/data-backup
      WARNING: Reducing active logical volume to 1.00 GiB.
      THIS MAY DESTROY YOUR DATA (filesystem etc.)
      Do you really want to reduce data/backup? [y/n]: y
      Size of logical volume data/backup changed from 41.33 GiB (10581 extents) to 1.00 GiB (256 extents).
      Logical volume data/backup successfully resized.
      $ sudo mount /dev/mapper/data-backup /mnt/backup
      $ sudo lvextend -l +100%FREE /dev/mapper/data-data
      Size of logical volume data/data changed from <70.86 GiB (18139 extents) to <117.10 GiB (29977 extents).
      Logical volume data/data successfully resized.
      $ sudo resize2fs -p /dev/mapper/data-data
      resize2fs 1.45.4 (23-Sep-2019)
      Filesystem at /dev/mapper/data-data is mounted on /run/overlay; on-line resizing required
      old_desc_blocks = 9, new_desc_blocks = 15
      The filesystem on /dev/mapper/data-data is now 30696448 (4k) blocks long.

      $ df -h /dev/mapper/data-backup /dev/mapper/data-data
      Filesystem            Size  Used Avail Use% Mounted on
      /dev/mapper/data-backup
                           752M   21M  665M   3% /mnt/backup
      /dev/mapper/data-data
                           115G   77M  110G   1% /run/overlay

Use netFIELDOS inside a virtual machine
---------------------------------------

This is basically possible (a special BSP/machine exists) and a
.ova image can be built for easy importing (e.g. VMWare)

The following restrictions apply:

* No PCI hardware access to cifX/netANALYZER boards is possible as PCI pass-through is usually unsupported.

.. note::
  TCP connections via netXTransport / netHOST are still possible

* Due to firewalling/bridges/NAT network scanning might be difficult (untested)
* EFI Boot mode must be setup for the VM
* 64-Bit Emulation must be supported on your host

Restoring a lost/broken device-label
------------------------------------

If your device has lost it's identify information (retrieved from so-called device-label)
they can be recovered. You will need to have a copy of the device label, or need access to
a server hosting these label.

.. note:: You can see that the device-label is lost, when looking at the serial number in cockpit which shows "MAC:001122334455"

Recovery is possible as follows (access to gateway database is required)

  .. code ::

     sudo mkdir -p /mnt/backup/nvd
     sudo curl http://gatewaydb/orbeon/gatewaydb/getjsonbymac/$(ifconfig eth0 | grep -o "HWaddr.*" | cut -d " " -f2 | tr -d ":" | tr "[:lower:]" "[:upper:]") -o /mnt/backup/nvd/device_data
     sudo reboot

If you have a copy or want to use a custom device-label you need to use the following sequence:

  .. code ::

     sudo mkdir -p /mnt/backup/nvd
     sudo cp <my_local_devicelabel> /mnt/backup/nvd/device_data
     sudo reboot

Device software
===============

How to create custom systemd services
-------------------------------------

As systemd's main directory /lib/systemd/system is write-protected
you need to use a different directory. Systemd scans several
directories for services. See the following (priority ordered) list:

* /etc/systemd/system/ (user-services, persistent)
* /run/systemd/system/ (temporary location)
* /lib/systemd/system/ (write-protected on netFIELDOS)

.. note:
   It is possible to overwrite existing services by placing them in a directory with higher priority

Install custom software
-----------------------

Custom software shall always be provided using docker containers.
As most of the filesystem is read-only installation is not possible.
You can copy and execute files to /usr/local/bin, but that is discouraged
in favor of docker:

* Create a container to run / install these applications

  .. code::

     docker run -it --name alpine_tools alpine

  .. note:
    Following options may be added depending on the use-case
    * "--net host" if physical access to host network devices is needed (e.g. tshark, nmap)
    * "--privileged" if full privileged access to the host system is required
    * "-v <dir_on_host>:<dir_in_container>" if host tools / directories are required inside the container

* Install tools

  .. code::

     apk update
     apk add <package>

* Run these tools

Access the device label
-----------------------

All Hilscher netFIELD devices have a signed device label (JSON format)
generated during production. It is bound to the device via it's MAC address
of the internal ethernet port. This verification is done during bootup where
only signed software is allowed and passed to a kernel mode driver
offering the included information.

A kernel mode driver offers access to the data via:

* Full content of the device label in JSON

  * Schema: meta-hilscher-netfield/recipes-core/device-data-driver/device-data.json.schema
  * Example: meta-hilscher-netfield/recipes-core/device-data-driver/device-data.json
* Decoded (single files for each node in JSON)
* Signature (base64 format)
* Public key used for verification

This data is available in linux sysfs (/sys/device_data) as follows:

+-----------------------------------+---------------------------------------------------------------------------------+
| File                              | Description                                                                     |
+===================================+=================================================================================+
| ``/sys/device_data/raw``          | Full content in JSON format                                                     |
+-----------------------------------+---------------------------------------------------------------------------------+
| ``/sys/device_data/signature``    | Base-64 encoded binary signature of JSON content (algorithm RSA/SHA512)         |
+-----------------------------------+---------------------------------------------------------------------------------+
| ``/sys/device_data/publickey``    | Public key used for verification                                                |
+-----------------------------------+---------------------------------------------------------------------------------+
| ``/sys/device_data/mac``          | MAC address used for device binding (extracted from "mac" node in root of JSON) |
+-----------------------------------+---------------------------------------------------------------------------------+
| ``/sys/device_data/product_name`` | Decoded node of full JSON content (Name of the product)                         |
+-----------------------------------+---------------------------------------------------------------------------------+

.. note: All further JSON nodes will be decoded in a directory structure in the same hierarchy as in JSON.

Temporarily modify systems files
--------------------------------

All system files are write-protected and cannot be changed.
To allow debugging a temporary overlay may be placed over some
folders to allow modification. These changes will be lost after
a reboot.

* Create a folder for your files and a working folder

  .. code::

     mkdir -p /tmp/usr /tmp/usr_work

* Mount an overlay on top of your rootfs folder you want to modify (/usr in this example)

  .. code::

     sudo mount -t overlay overlay -o lowerdir=/usr,upperdir=/tmp/usr,workdir=/tmp/usr_work /usr

* Write to /usr

Customize docker network settings
---------------------------------

This is possible using the DeviceManager / Cockpit web UI, or
manually as follows:

**User docker**
Modify /etc/docker/daemon.json:

* Add "bip": "<ip>/<prefix> to customize docker0 bridge
* Add "default-address-pools" to customize addresses of generated networks

.. code-block:: json
   :caption: /etc/docker/daemon.json

   {
     "bip": "192.168.253.1/24",
     "default-address-pools":[
       {"base": "172.50.0.1/16", "size": 24}
     ]
   }

The example above will make docker0 default bridge show up with
network 192.168.253.1/24.

Each created network will be derived from "172.50.0.1/16" pool
with a prefix of 24, resulting in the first bridge being assigned
a "172.50.0.1/24", the second a "172.50.1.1/24" and so on.

**IoT edge docker**
/etc/docker/iotedge.json and "/etc/default/iotedge" must be modified:

* Add "default-address-pools" to customize addresses of generated networks (same as for standard docker) in /etc/docker/iotedge.json
* Change BRIDGE_IP in "/etc/default/iotedge"

    delete "/run/overlay/iotedge-docker/network/files/local-kv.db" to make sure docker uses the new IP and not a cached one.
    sudo rm -f /run/overlay/iotedge-docker/network/files/local-kv.db

    .. note:: When doing the port change before on-boarding or first starting iotedge-docker, there is no need to delete local-kv.db.

.. code-block:: json
   :caption: /etc/docker/iotedge.json

   {
     "default-address-pools":[
       {"base": "172.51.0.1/16", "size": 24}
     ]
   }

.. code-block::
   :caption: /etc/default/iotedge

   BRIDGE_IP="192.168.254.1/24"

The example above will make iotedge0 default bridge show up with
network 192.168.254.1/24.

Each created network will be derived from "172.51.0.1/16" pool with
a prefix of 24, resulting in the first bridge being assigned a
"172.51.0.1/24", the second a "172.51.1.1/24" and so on.

Use TPM 2.0 for iotedge onboarding
----------------------------------

First of all you need a hardware with a TPM 2.0 which is properly setup with an endorsement key (EK)
and a storage root key (SRK) created as follows:

.. code-block::
   :caption: TPM provisioning

   # Reset the TPM
   tpm2_clear

   # Create Endorsement Key
   tpm2_createek -c ek.ctx
   tpm2_evictcontrol -c ek.ctx 0x81010001
   tpm2_readpublic -c ek.ctx -o ek.pub
   tpm2_flushcontext -t
   tpm2_flushcontext -l
   tpm2_flushcontext -s

   # Create Storage Root Key
   tpm2_createprimary -C o -g sha256 -c srk.ctx -Grsa2048:aes128cfb -a "fixedtpm|fixedparent|sensitivedataorigin|userwithauth|noda|restricted|decrypt"
   tpm2_evictcontrol -C o -c srk.ctx 0x81000001
   tpm2_readpublic -c srk.ctx -o srk.pub
   tpm2_flushcontext -t
   tpm2_flushcontext -l
   tpm2_flushcontext -s

Second you will need to create a DPS device in Microsoft Azure using the base64 encoded EK public key
and a unique registration id.

.. code-block::
   :caption: Cloud endorsement key

   base64 ek.pub

Third you must adjust iotedge configuration as follows:

.. code-block::
   :caption: /etc/aziot/config.toml

   [tpm]
   tcti = "device:/dev/tpmrm0"
   # # Authorization values for use of the endorsement and owner hierarchies, if
   # # necessary. By default, these are empty strings.
   # [tpm.hierarchy_authorization]
   # endorsement = "hello"
   # owner = "world"
   [provisioning]
   source = "dps"
   global_endpoint = "https://global.azure-devices-provisioning.net"
   id_scope = "<scope_id>"
   [provisioning.attestation]
   method = "tpm"
   registration_id = "<registrationid>"

Last you need to apply the configuration

.. code-block::
   :caption: Apply configuration

   sudo iotedge config apply
   sudo systemctl enable aziot-edged

.. Note::
   It is possible to use netFIELDOS on a virtual machine with VirtualBox 7.x
   which supports a virtual TPM 2.0 inside virtual machines.


Indices
=======

* :ref:`genindex`
