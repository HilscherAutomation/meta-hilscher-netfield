=========
Use-Cases
=========

.. :Author: Michael Trensch <mtrensch@hilscher.com>

Introduction
============

As netFIELD OS is only a very minimalistic base system,
most use-cases are driven by / optimized for devices attached to a netfield.io
cloud instance.

All custom software will be installed / run in docker containers which are
either managed locally or by netfield.io. No custom software shall be installed
into the base system.

The device is manageable via
 * local device manager web-based UI (reachable via https://<ip>)
 * command line interface via local tty or ssh

Device Life Cycle - Use-Cases
-----------------------------

#1. Use-case: Device already running netFIELDOS (customer)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 * System will be executed from built-in physical medium
 * Recovering a bricked device is only possible by

   * special USB mass storage device (recovery stick)
   * fastboot
   * device manufacturer

 * Firmware is updatable via web/usb (swupdate feature)
 * *(wishlist)* Failure during device-update will result in booting the
   previous firmware (called alternative firmware) ->
   save bootloader, atf, watchdog and rollback
 * device can be backed up during runtime (to produce a clone) and
   restored during reboot
   *(wishlist)* Backup and restore to/from external device (USB, NFS)

   * full backup (including firmware)
   * data backup
 * Support for additional keys (OEM, etc.)

#2. Use-case: Production of a netFIELDOS device
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Prerequisite:
 * System contains at least a bootloader
   (special version that does not check signatures)
 * Special BootP/TFTP environment

 * Bootloader will enter production mode when

   * No firmware was found
   * manually forced into production mode (button)
 * Installs initial software (wic)
 * Prepares hardware (mmc config, fuses, ...)
 * *(optional)* Personalization via device label

#3. Use-case: Support/Service
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 * *(recommended)* Clone/save internal flash/mmc
 * Repair bricked devices via

   * USB (recovery, livestick??????)
   * console
 * Reprogramming flash/mmc (e.g. adaptor)

#4. Use-case: Development of a netFIELDOS device (debug firmware)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 * See #1 (device already running netFIELDOS)
 * Livestick?????
 * manually boot alternate firmware
 * extended software packages
 * Ability to catch fatal errors (e.g. drop to shell)
 * Increased log verbosity / level
 * Access to bootloader console

Basic Features
^^^^^^^^^^^^^^
 * No components with GPLv3 license are included
 * One medium containing **ALL** partitions
   **NO** distribution across multiple media
 * **ONE** medium must be defined as boot device
 * Bootup sequence starting at bootloader is fixed as follows:
   **NOTE:** Bootloader searches for **signed** scripts on devices

   * manually select an option from below via bootmenu/pin
     *(idea)* Select via file before executing reboot
     with one of the following additional options

     * Previously running firmware (alternate boot)
     * Fastboot recovery
     * bootloader console (**debug only**)

   * USB mass storage device (recovery)
   * primary boot device (defined by BIOS / jumper)
   * BootP/TFTP

 * Bootimage types: **signed** fitImage with kernel, initramfs, dtb, ...)
   (exceptions may be platform specific)
 * Root filesystem: Only read-only as signed squashfs file
 * writeable overlay is only supported via a separate data partition
 * Boot configuration is stored in a signed text file on system partition
   containing:

   * description
   * kernel
   * rootfs file to use
   * overlay directories

 * Possibility to inject multiple signed archives with the name "initrd-api-\*"
   (e.g. firmware) into boot process via following locations:

   * system partition
   * boot device (e.g. USB stick)
 * backup/restore is only supported via backup partition

   **NOTE:** Backup will be done on running system, while restore
   will be done during reboot of a device
 * *(optional)* signed device-label which must reside as file with name
   "device_data" in one of the following locations.
   It will automatically be distributed to all known locations

   * backup/nvd
   * (EFI systems only, read-only)
     /sys/firmware/efi/efivars/hilscher-23682453-5d09-4e17-a1a6-f5efb21996d9

     * niot-e-vm-en / intel: Generate serial / product number in platform_init
       (efi/hmi-xxx) and pass fake device label

   **NOTE:** Devicelabel is bound to device via MAC address of eth0
 * Remote access via SSH / device manager web interface
 * *(optional)* Cloud attaching to netfield.io via azure-iot services
 * Linux security services

   * Auditing
   * Login Brute-Force Protection
   * Logging
   * Mandatory Access Control (AppArmor)
   * Seccomp

End User Use-Cases
------------------

Cloud managed device
^^^^^^^^^^^^^^^^^^^^

Device is managed by a netfield.io cloud instance and needs to be onboarded to
this instance via local device manager web UI.

Containers will be deployed using the netfield.io cloud APIs or UI.

This is the default use-case and is meant to be used to extract data from a 
machine via an edge device, which can be attached to a production machinery,
and provide data to the cloud instance.
Data can then be processed or visualized inside the netfield.io cloud instance
(or an additional service)

All data is distributed by a local system bus, which is MQTT based, and can
easily be forwarded to netfield.io.


Local managed device
^^^^^^^^^^^^^^^^^^^^

Installing local user software can be done using the default docker mechanisms.
There is also an option to manage docker containers / images via the local
device manager web UI.

Example:

.. code-block:: bash

   docker run -d --name webserver -p 8080:80 nginx

For further information, refer to official docker guides.

