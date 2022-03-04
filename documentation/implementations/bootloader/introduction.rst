
.. :Author: Sebastian Döll <sdoell@hilscher.com>

Introduction
============
The bootloader provides a :ref:`consistent software interface<bootloader_feature>` over multiple platforms. The software interface guarantees :ref:`Verified Boot<security>` from multiple mediums. To be flexible for future development the bootloader searches for signed scripts instead of a bootable image directly.

.. Note:: The term *Verified Boot* highly depends on the underlying hardware and therefore may be limited on some platforms. For more information refer to :ref:`Verified Boot<security>` or the specification of the hardware.

.. _bootloader_feature:

Features
--------
	* verified boot (default:sha256 and RSA2048)
	* script based boot (signed only)
	* kernel FIT image format (signed only)
	* dual boot/multi boot
	* USB boot
	* network boot (PXE boot)
	* Fastboot
	* console/netconsole (debug image only)


.. _boot_process:
	
Boot Process
------------

The boot process covers three different scenarios: 

Regular Boot
	* start netFIELD OS (latest installed version)

Alternate Boot
	* boot alternate firmware/netFIELD OS version
	* system recovery
	* user defined boot behavior

Production/Recovery Boot:
	* PXE/network boot

The boot procedure is a combination of a :ref:`builtin<builtin_boot_process>` and a :ref:`script<uboot_bootscript>` based boot process. The *script based* boot method adds great flexibility allowing to change the boot behavior retrospectively while preserving the security requirements at the same time. The builtin process covers the *Production Szenario* and loads the boot script. The started boot script then provides the *Regular* and *Alternate Boot Process*. In contrast to the automatically executed *Production* and *Regular Boot Process*, the :ref:`Alternate Boot Process<boot_control>` need to be triggered by the user.

 
.. _builtin_boot_process:

Builtin Boot Process
^^^^^^^^^^^^^^^^^^^^

As shown in the flowchart :ref:`Builtin Boot<flowchart_builtin_boot_flow>`, the bootloader initially searches for a :doc:`boot script<scripts>` *boot.scr* on USB and then on the *Primary Boot Device* [1]_. In case the found script is successfully verified it will be executed. In case of a verification failure the boot process stops. If no scripts are found the device will start network boot via :doc:`PXE (/network) boot<pxeboot>`. This may be the case at production time or for recovery purposes for example. For detailed information about devices with hardware based secure boot and it's initial verification step, prior to the software start *Bootloader Start*, please refer to :ref:`Verified Boot<security>`.

.. _flowchart_builtin_boot_flow:
.. graphviz::
	:align: center
	:caption: Flowchart: Builtin Boot
   
	digraph foo1 {
		//size = "15,2";

		//graph [autoscale = true];
		//node [autoscale = true, fontsize = 5];
		//edge [autoscale = true, fontsize = 5];

		//click [label="Enlarge by open in new tab", href="#"];
      
		Start [ label = "Bootloader Start" ]
		b1 [label = "Check for boot.scr on USB", shape="diamond", tooltip=""];
		b3 [label = "Verify and load boot.scr", shape="rect", tooltip=""];
		b4 [label = "Check for boot.scr on Primary Boot Device²", shape="diamond", tooltip="" href="../implementations/bootloader/introduction.html#footnotee"];
		b5 [label = "Start pxe/tftp boot", shape="rect", tooltip=""];
		b6 [label = "Stop boot", shape="rect", tooltip=""];
		b7 [ label ="", shape = "point", tooltip=""];
		End [ label = "Run boot script", tooltip=""];

        Start -> b1
		b1 -> b4 [ label = "Not found", color="red", tooltip=""];
		b1 -> b3 [ label = "Found", color="green", tooltip=""];
		b3 -> b6 [ label = "Failed", color="red", tooltip=""];
		b3 -> b7 [ label = "OK", dir="forward", color="green", arrowhead="none", tooltip=""];
		b4 -> b5 [ label = "Not found", color="red", tooltip=""];
		b4 -> b3 [ label = "Found", color="green", tooltip=""];
        b7 -> End [ color = "green", tooltip=""]
	}


.. _uboot_bootscript:

Boot Script
^^^^^^^^^^^

The following simplified flow shows the script based part of the netFIELD OS default boot process, which is started by the :ref:`builtin boot process<builtin_boot_process>`. If no user interaction is perceived the boot process will follow the *Regular Boot Path* starting the latest netFIELD OS version. In case the user interrupts the process an *Alternate Boot Path* will be executed. In this case the user will be able to select via the provided bootmenu an alternate boot option (see :ref:`Alternate Boot Control<boot_control>`). For implementation details of boot script refer to :doc:`netFIELD OS Boot Script<bootscript>`.

.. _flowchart_script_boot_flow:

.. graphviz::
	:align: center
	:caption: Flowchart: Script based boot flow
   
	digraph foo1 {
		//size = "15,2";

		//graph [autoscale = true];
		//node [autoscale = true, fontsize = 5];
		//edge [autoscale = true, fontsize = 5];

		//click [label="Enlarge by open in new tab", href="#"];
      
		Start [ label="Start Boot Script" ]
		a1 [label = "User interaction?\nStop Regular Boot?", shape="diamond", tooltip="this is a tooltip"];
		a2 [label ="Start Regular Boot Process", shape = "rect", tooltip=""];
		a3 [label ="Verify Image", shape="diamond", tooltip=""];
		a4 [label ="Boot verified image", shape = "oval", tooltip=""];
		a5 [label ="Stop Boot", shape="oval", tooltip=""];
		a6 [label ="Start Alternate Boot Process", href="../implementations/bootloader/introduction.html#boot-control", target="_parent", shape="rect", tooltip=""];
		a7 [label ="Handle user input", shape="oval", tooltip=""];

        Start -> a1
		a1 -> a2 [ label = "no", tooltip=""];
		a2 -> a3 [ label = "", tooltip=""];
		a3 -> a4 [ label = "ok", tooltip=""];
		a3 -> a5 [ label = "failed", tooltip=""];
		a1 -> a6 [ label = "yes", tooltip=""];
		a6 -> a7 [ label = "", tooltip=""];
	}

.. _boot_control:

Alternate Boot Control
^^^^^^^^^^^^^^^^^^^^^^
The Alternate Boot Control extends the common boot flow by the following alternative boot options:

* | **Multi-Boot**
  | Allows to switch between installed firmware images
* | **Recovery** via :doc:`Fastboot<fastboot>`
  | Allows to recover a device
* | Bootloader commandline interface (available only if debug version is installed)
  | Allows to enter custom boot path via bootloader provided commands

The boot script dynamically creates a bootmenu that allows to switch between the noted boot options. For more information about the bootmenu and how to control refer to :doc:`Bootmenu<bootmenu>`.


.. _security:

Verified Boot
-------------
To guarantee a secure and trustful runtime the netFIELD OS uses the principle of a *Chain of Trust*. Depending on the hardware the *Root of Trust* may be provided by the hardware or by the software e.g. the bootloader. In contrast to a hardware based verification support the software does not allow verification of the initial running software. Security aware hardware adds a verification step before the initial software start (bootloader) (see :ref:`Bootloader Start<flowchart_builtin_boot_flow>`). In case the verification fails the software will not be started. Devices without hardware based support will always start the initial peace of software. In case of the software variant assuming this initial software can not be modified (for example by protecting from physical access) the ROT starts at the *Verify and load boot.scr* step (see :ref:`Builtin Boot<flowchart_builtin_boot_flow>`).

For a complete overview of netFIELD OS provided COT refer to :doc:`Chain of Trust<../security/cot>`.

.. Note:: Depending on the target environment and the security requirements the correct hardware need to be chosen. Note that data written via fastboot as well as boot parameter setup via PXE will not be verified.

For detailed information about the security aspects of netFIELD OS refer to :doc:`Security Aspects<../../concepts/security>` of the netFIELD OS.


.. [1] Primary Boot Device: The primary boot device is the device from which a platform boots the netFIELD OS. The PBD is platform specific. For more information refer to the device specification.
