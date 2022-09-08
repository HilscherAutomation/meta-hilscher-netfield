=================
Build Information
=================

.. :Author: Sebastian Döll <sdoell@hilscher.com>

.. _bootloader_device_tree_table:

General Settings
^^^^^^^^^^^^^^^^^

+-------------------------------------+---------------------------+-------------------------------------------------------------------------------------------------------+
| Name                                | Value                     | Description                                                                                           |
+=====================================+===========================+=======================================================================================================+
| ``IMAGE_FEATURES``                  | "hab"                     | This enables signature creation of the initial boot binaries. Supported only in case hardware         |
|                                     |                           | supported verified boot. This is not available on all platforms.                                      |
+-------------------------------------+---------------------------+-------------------------------------------------------------------------------------------------------+


Device Tree
^^^^^^^^^^^

+-------------------------------------+-------------------------------------------------------------------------------------------------------+
| Name                                | Description                                                                                           |
+=====================================+=======================================================================================================+
| ``UBOOT_DTB_NAME``                  | Name of the Device Tree to be used. If not set $KERNEL_DEVICETREE will be used. If this fails         |
|                                     | ${MACHINE}.dtb will be used.                                                                          |
+-------------------------------------+-------------------------------------------------------------------------------------------------------+
| ``PREFERRED_PROVIDER_virtual/dtb``  |  Set to recipe as external source in case the device tree is not provided by u-boot.                  |
+-------------------------------------+-------------------------------------------------------------------------------------------------------+


.. _bootloader_menu_var_table:

Bootloader Menu
^^^^^^^^^^^^^^^
For information refer to :doc:`boot menu<bootmenu>`. Not supported on all platforms.

+---------------------------------+---------------------------+-------------------------------------------------------------------------------------------------------+
| Name                            | Value                     | Description                                                                                           |
+=================================+===========================+=======================================================================================================+
| ``IMAGE_FEATURES``              | "uboot-disable-menu"      | This will disable the menu availability.                                                              |
+---------------------------------+---------------------------+-------------------------------------------------------------------------------------------------------+
| ``IMAGE_FEATURES``              | "uboot-disable-fastboot"  | This will only provide the Multiboot option.                                                          |
+---------------------------------+---------------------------+-------------------------------------------------------------------------------------------------------+
| ``IMAGE_FEATURES``              | "debug-tweaks"            | Apart from Multiboot, this will enable the console and Fastboot (independently of the settings of     |
|                                 |                           | "uboot-disable-menu" or "uboot-disable-fastboot")                                                     |
+---------------------------------+---------------------------+-------------------------------------------------------------------------------------------------------+
| ``IMAGE_FEATURES``              | "u-boot-gpio-menu"        | Enables boot menu control via GPIO. This will include the configuration *gpio-menu.cfg*,              |
|                                 |                           | see table below :ref:`Pin Controlled Menu<bootloader_gpio_menu_table>`.                               |
+---------------------------------+---------------------------+-------------------------------------------------------------------------------------------------------+

.. _bootloader_gpio_menu_table:

**Pin Controlled Menu**

The following table shows the options of the gpio-menu.cfg configuration file.

+---------------------------------+-------------------------------------------------------------------------------------------------------+
| Name                            | Description                                                                                           |
+=================================+=======================================================================================================+
| ``CONFIG_BOOTMENU_GPIO``        | Enables GPIO based boot menu, do not change.                                                          |
+---------------------------------+-------------------------------------------------------------------------------------------------------+
| ``CONFIG_BOOTMENU_GPIO_CTRL``   | Set to GPIO label (device tree) which is used to control boot menu.                                   |
+---------------------------------+-------------------------------------------------------------------------------------------------------+
| ``CONFIG_BOOTMENU_GPIO_LED``    | Set to LED label (device tree), which should be used for signalling .                                 |
+---------------------------------+-------------------------------------------------------------------------------------------------------+
