=======
Scripts
=======

.. :Author: Sebastian Döll <sdoell@hilscher.com>

The bootloader allows to execute u-boot commands in a script base format. For more information of commands and syntax refer to [1]_.

For default search order of boot scripts refer to :ref:`Boot Flow<flowchart_builtin_boot_flow>`. 

As the bootloader will only load and execute signed and correctly verified scripts it is necessary to sign the script. For example scripts refer to *meta-hilscher-netfield/recipes-bsp/u-boot/u-boot/boot-script-fit/*..
TODO: show how to sign or to use recipe


.. code-block:: bash
	:linenos:
	:caption: Example how to load u-boot script
	
	# set loadaddr to area of free RAM
	setenv loadaddr 0x50000000
	# load my_script.scr from first partition of the first found USB device
	fatload usb 0:1 $loadaddr my_script.scr
	# execute loaded script
	source $loadaddr

.. [1] `Information about u-boot scripting <https://www.denx.de/wiki/DULG/UBootScripts>`_
