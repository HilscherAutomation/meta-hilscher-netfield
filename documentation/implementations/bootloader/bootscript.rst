===========
Boot Script
===========

.. :Author: Sebastian Döll <sdoell@hilscher.com>

The netFIELD OS boot script is a specific implementation of a :doc:`u-boot script<scripts>` which is part of the :ref:`common netFIELD OS boot process <boot_process>`. When started it will parse all found *Boot Configuration Files*. The *Boot Configuration Files* keep all the required information about the relation of the kernel, the boot parameter and it's root file system. Depending on the :ref:`image configuration<bootloader_menu_var_table>` the boot script will create a bootmenu that allows the user to switch between the following options:

* **Multiboot**
* **Fastboot**
* **Console**

.. Note:: By default (without any :ref:`configuration<bootloader_menu_var_table>` change) the menu will provide only the Multiboot and Fastboot option.

At startup the boot script searches for a boot configuration file (boot.cfg='Default Boot', aboot.cfg='Alternative') on the first and the second partition of the primary boot device. Based on the parsed configurations and configuration a bootmenu will be dynamically created. For more information about the configuration files and it's syntax refer to :doc:`boot_cfg<../operatingsystem/initramfs-framework/10-netfield_init>`. For more information about the bootmenu and its control refer to :doc:`boot menu<bootmenu>`.

.. _bootscript:
.. graphviz::
	:align: center
	:caption: Flowchart: netFIELD OS Boot Script
   
	digraph foo1 {
		//size = "15,2";

		//graph [autoscale = true];
		//node [autoscale = true, fontsize = 5];
		//edge [autoscale = true, fontsize = 5];

		//click [label="Enlarge by open in new tab", href="#"];
      
		Start [ label = "Script Start" ]
		b1 [label = "Check for boot configuration file on *primary boot device*", shape="diamond", tooltip=""];
		b2 [label = "Create boot menu based on found boot configurations\n and image configurations", shape="rect", tooltip=""];
		b3 [label = "User interrupt?", shape="diamond", tooltip=""];
		b4 [label = "Handle user input. Set menu selection.", shape="rect", tooltip=""];
		b5 [label = "Continue boot / start menu selection", tooltip=""];

		Start -> b1
		b1 -> b1 [ label = "Iterate over partitons", tooltip=""];
		b1 -> b2 [ label = "All partitions parsed", tooltip=""];
		b2 -> b3 [ label = "", tooltip=""];
		b3 -> b4 [ label = "User input", tooltip=""];
		b4 -> b5 [ label = "User input finished", tooltip=""];
		b3 -> b5 [ label = "No user input", tooltip=""];
	}

