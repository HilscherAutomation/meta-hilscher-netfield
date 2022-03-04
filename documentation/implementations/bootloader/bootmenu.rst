==========
Boot Menu
==========

.. :Author: Sebastian Döll <sdoell@hilscher.com>

.. _boot_menu:

Depending on it's configuration the bootloader provides a boot menu offering the following options:

* :ref:`Multi Boot/Dual Boot<bootmenu_multiboot>`
* :ref:`Fastboot<bootmenu_fastboot>`
* :ref:`Console (debug only)<bootmenu_console>`

For information about the internals of the boot menu refer to :doc:`netFIELD OS Boot Script<bootscript>`.

By default the latest installed netFIELD OS version. To enter Alternate Boot halt the auto boot process by pressing any key and selecting the mode.

.. Note:: How to control the boot menu depends on the hardware and it's interfaces. In case the device does not provide interfaces for common HID the bootmenu may be controlled for example via pin and netconsole (for details refer to the specification of the hardware).

.. _bootmenu_multiboot:

Multi Boot
----------
The Dual Boot option allows to switch between the latest and the previous installed netFIELD OS version. In case of a system failure after an update it is possible to switch back to the previous version.

   
.. _bootmenu_fastboot:

Fastboot
--------
In case the operating system is in an inoperational state the device can be restored via fastboot. For more information about Fastboot and how to use it refer to :doc:`Fastboot<fastboot>`. The device IP address is set to **192.168.253.1**.

.. Note:: In case you are connected via :ref:`netconsole<bootmenu_console>` and selecting Fastboot the console connection will be shutdown since both services can't be run in parallel. To restart netconsole reset the device.


.. _bootmenu_console:

Console / netconsole
--------------------

The console mode allows to enter u-boot commands and thereby custom boot path. For security reasons, this mode is only available if a debug image is running.

In case of devices without serial interface or display support the console will be redirected via network. The bootloader can than be controlled via network by using *netconsole*. The device will be reachable under **192.168.253.1** and expects the client's IP to be set to **192.168.253.2**.

The connection can be established using the netconsole script provided by the u-boot source via the following command:

.. code-block:: bash
	:linenos:
	:caption: Example how to establish netconsole
    
	./netconsole -i 192.168.253.1

For more information about netconsole and how to use it refer to u-boot source.

