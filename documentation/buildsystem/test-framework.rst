==============
Test Framework
==============

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Since new features and bug fixes are usually built and tested locally on only one specific target device (product),
issues on other target devices with the same software base may only be noticed days or weeks after a git merge.
To avoid this, an automated test of new code or resulting software image should be executed on all known target devices.
For a continuous improvement in software quality, expandable test cases addressing known/critical issues shall be created.

A workbench with test devices (DUT) is set up to implement this concept.
All DUTs are connected to the existing LAN via a network switch and a DHCP server assigns a static IP to each DUT.
Our build server assumes the role of the test machine and executes yocto build jobs with integrated test support.
The test support is implemented in use of the yocto framework "testimage.bbclass".

Test Workbench
==============

Device Under Test (DUTs)
   .. csv-table::
      :header: IP, Device name (DUT), User / Password
      :widths: 10, 30, 30

      10.11.4.225, netfield-compact-x8m-rev1, "admin / Hilscher, root / <none>"
      10.11.4.226, netfield-iolink-edge-gw-rev2, "admin / Hilscher, root / <none>"
      10.11.4.227, niot-e-tpi51-en-re, "admin / Hilscher, root / <none>"
      10.11.4.228, niot-e-tijcx-gb, "admin / Hilscher, root / <none>"

Requirements
============

local.conf
   To create a yocto image with test support, you need to add the following lines to your local.conf file.

   .. code-block:: bash

      # ------------------------------------------------------------------------------
      INHERIT += "testimage"

      # Define the test controller used to access the DUT.
      # NOTE: python3-pexpect is requiered by TEST_TARGET HilscherTarget.
      TEST_TARGET ?= "HilscherTarget"

      # Add yocto test cases ...
      TEST_SUITES = "ping ssh syslog date dmesg apparmor"

      # Add hilscher test cases ...
      TEST_SUITES_append += "hilscher"
      TEST_SUITES_append += "netfieldos"

      TEST_SERVER_IP ?= "tbd"

      # IP address of DUT
      TEST_TARGET_IP ?= "tbd"

      # The tests can be run automatically each time an image is built if you set
      #TESTIMAGE_AUTO = "1"

      # NOTE:
      # A passwordless root ssh shell is required by yocto test framework.

      # This can be done by yocto IMAGE_FEATURES ...
      #EXTRA_IMAGE_FEATURES_append += "empty-root-password allow-empty-password  debug-tweaks"
      #EXTRA_USERS_PARAMS_append += "usermod -s /bin/sh root;"

      # or manually on the test device (DUT) ...
      # sudo usermod -s /bin/sh root
      # sudo sed -i 's/^root:[*x]:/root::/' /etc/shadow
      # sudo sed -i 's/^[#[:space:]]*PermitEmptyPasswords.*/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
      # sudo sed -i 's/^[#[:space:]]*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
      # sudo sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth
      # ------------------------------------------------------------------------------

Passwordless root (ssh) shell
   As the test implementation runs commands on the test device (DUT) over ssh, a ssh root shell access without password is required on the DUT.

   For example, a one-time configuration must be done on netfield-os image devices as follows.
      .. code-block:: bash

         sudo usermod -s /bin/sh root
         sudo sed -i 's/^root:[*x]:/root::/' /etc/shadow

         sudo sed -i 's/^[#[:space:]]*PermitEmptyPasswords.*/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
         sudo sed -i 's/^[#[:space:]]*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

         sudo sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth

Build a yocto image with test support
   After the local.conf has been edited, an image with test support can be built as usual.

   .. code-block:: bash

      bitbake <image>

Run a test on test device (DUT)
   After an image with test support has been built, it can be tested on the DUT as follows.

   .. code-block:: bash

      bitbake <image> -c testimage

Hilscher test controller
========================

meta-hilscher-netfield/lib/oeqa/controllers/hilschertarget.py
   .. csv-table::
      :header: Controller name, Description
      :widths: 10, 40

      **HilscherTarget (ssh based)**, "::

         1. Upload the last image to DUT
         2. Update the DUT by calling the swupdate-client service => Rebooting DUT
         3. Wait for completely boot up the DUT
         4. Start the defined test cases (TEST_SUITES)
      "

Hilscher test cases
===================

meta-hilscher-netfield/lib/oeqa/runtime/cases/nfos_firmware.py
   .. csv-table::
      :header: Test name, Description
      :widths: 10, 40

      **test_swupdate**, "Test the update capability of the system."
      **test_required_files**, "Test if /firmware.image_name, /firmware.manifest, /firmware.version, /etc/hwrevision exists."
      **test_firmware_image_name**, "Read out the /firmware.image_name to test if the last image build was successfully installed by the test framework (controller)."

meta-hilscher-netfield/lib/oeqa/runtime/cases/nfos_hardware.py
   .. csv-table::
      :header: Test name, Description
      :widths: 10, 40

      **test_proc_iomem_entries**, "Read out the /proc/iomem to test the availability of expected hardware entries."
      **test_sys_class_leds_files**, "Test the /sys/class/leds directory for expected LED devices entries."
      **test_sys_class_gpio_files**, "Test the /sys/class/gpio directory for expected GPIO devices entries."

meta-hilscher-netfield/lib/oeqa/runtime/cases/nfos_system.py
   .. csv-table::
      :header: Test name, Description
      :widths: 10, 40

      **test_backup_mount**, "Test if the LVM backup partition is mount to /mnt/backup."
      **test_partitioning**, "Test the partition size of the boot, rescue and system partition. (**Note**: LVM partitions are currently skipped!)"
      **test_arp_support**, "Test for availabilty of ``arp`` tool."
      **test_backup**, "Test backup/restore functionality."
      **test_zram**, "Test if ``/dev/zram0`` is used for swap memory."
      **test_firewall**, "Test if firewall zones are correctly assigned (**Note**: When using multiple interfaces, only eth0 shall have link up)"
      **test_hostname_change**, "Test if hostname changes are properly reflected in /etc/hosts for local lookups, e.g. by containers."

meta-hilscher-netfield/lib/oeqa/runtime/cases/nfos_user_group_permissions.py
   .. csv-table::
      :header: Test name, Description
      :widths: 10, 40

      **test_netadmin_group_permissions**, "Test *filesystem*, *sudoers* and *polkit* permissions for group *netadmin* (See: :ref:`special_usergroups_and_their_permissions`)"
      **test_timeadmin_group_permissions**, "Test *filesystem* and *polkit* permissions for group *timeadmin* (See: :ref:`special_usergroups_and_their_permissions`)"
      **test_docker_readonly_group_permissions**, "Test *filesystem* and *docker* permissions for group *docker-readonly* (See: :ref:`special_usergroups_and_their_permissions`)"
