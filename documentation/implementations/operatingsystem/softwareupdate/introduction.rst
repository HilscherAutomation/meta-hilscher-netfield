===============
Software-Update
===============

.. :Author: Sebastian Döll <sdoell@hilscher.com>

Introduction
^^^^^^^^^^^^

The netFIELD OS provides *safe* ways to *update* and to *recover* a device. A *recovery* or *upate process* can be executed via the Web interface or triggered by a plugged in USB device. In case the web interface is not accessible (e.g. in case of a bricked device) chose USB.

The build environment automatically creates the update and recovery images. The images will be published under ${DEPLOY_DIR}/dist/${MACHINE}/.
To control the build of update and recovery images set ``$NETFIELD_IMAGES`` accordingly.

================================ ==========================================================================================================================
Value                            Description                                                                                                     
================================ ==========================================================================================================================
``recovery.zip``                 Set ``$NETFIELD_IMAGES`` to ``recovery.zip`` to create a recovery image required for USB recovery.
``recovery.swu``                 Set ``$NETFIELD_IMAGES`` to ``recovery.swu`` to create a recovery image required for Web recovery.
``update.swu``                   Set ``$NETFIELD_IMAGES`` to ``update.swu`` to create a update image required for Web update.
================================ ==========================================================================================================================

What does safe mean in this context:
------------------------------------
Safe in this context means that all update/recovery images are signed and verified during the update/recovery process.

.. Note:: Although an interrupted (e.g. power interruption) update process may brick the device.

What does "update" mean in this context:
----------------------------------------
The update process will update the read only partition of the device and will not touch any of the RW partition's of the device. For detailed information of the root file system refer to :doc:`Root File System<../filesystem/filesystem>`.

.. NOTE:: In production environment it is only possible to update to greater versions. In case of debug version it is possible to downgrade. 

What does "recover" mean in this context:
-----------------------------------------
A recovery process will overwrite the complete boot device. As a consequence all user data will be lost. A recovery allows a software downgrade as well. For detailed information of the root file system refer to :doc:`Root File System<../filesystem/filesystem>`.

* It is possible to recover a bricked device (at least the bootloader need to be in an operational state).
* Reset to specific software version. Note that this will delete all user data.


How to recover a device
^^^^^^^^^^^^^^^^^^^^^^^

USB based:
----------

.. Note:: For devices without an USB interface please refer to :doc:`Fastboot<../../bootloader/fastboot>` or :doc:`PXE boot<../../bootloader/pxeboot>`.

1. Prepare a FAT formatted USB device and name it "RECOVERY"
2. Copy the USB recovery image (*\*.recover.zip*) of the device to be recovered onto an USB device and extract it. 
3. Plug it in the hardware an reset/reboot the device
4. When the recovery process is finished the device will shut down. Then remove the USB device and reset/reboot the hardware

.. Note:: Details/Background: The recovery process is based on the initrd-api technique. After successful recovery and it's reboot some initializing steps may be executed (e.g. reformatting/resizing of the root file system). Do not shut down during this process.

In case the device provides a serial interface or a HDMI interface the update progress can be watched. as an alternative a log file will be written onto the USB update stick. During the update process the write process may be signaled by an LED blinking with 1Hz frequency.

Web based:
----------

1. Log in via Web interface
2. click on "System update"
3. Select the recovery image (*\*.recovery.swu*)
4. Upload and start system recovery

Details/Background:
netFIELD OS uses SWUpdate based mechanism to recover to specific system state. After successful verification and image extraction the the recover process equals the USB recovery process but stores the initrd-api script including the new binary image on the system partition.


How to update a device
^^^^^^^^^^^^^^^^^^^^^^

Web interface:
--------------

1. Log in via Web interface
2. click on "System update"
3. Select the update image (*\*.update.swu*)
4. Upload and start system update



.. Note:: In case of a debug image (IMAGE_FEATURES = "debug-tweaks") the netFIELD OS additionally provides direct access to the SWUpdate web interface via http://[device IP]:8080.

