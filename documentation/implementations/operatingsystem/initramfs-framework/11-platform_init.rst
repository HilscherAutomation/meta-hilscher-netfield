====================================================
Platform specific initialization (**platform_init**)
====================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-platform-init*

Script
   *platform_init*

----

The *platform_init* script is responsible to perform platform specific initializations,
such as loading specific kernel drivers, device tree overlays and so on.
In addition, platform-specific peripherals like *GPIOs* or *LEDs* are deployed via symbolic links in the */var/platform* directory.
This directory is pre-mounted and later moved to the runtime RootFS by the *netfield_init* respectively the *finish* script. 
By this way, deeper knowledge about hardware and software implementations are abstracted to simplify the user access.

.. code-block:: bash
   :linenos:
   :caption: Example: Code snippet of **platform_init** script

   ...
   
   # GPIO outputs
   ln -s /sys/class/gpio/gpio433/value  /var/platform/gpio_out0

   # GPIO inputs
   ln -s /sys/class/gpio/gpio430/value  /var/platform/gpio_in0
   ln -s /sys/class/gpio/gpio432/value  /var/platform/gpio_in1

   # LEDs
   ln -s /sys/class/leds/act_green/brightness  /var/platform/led_act_green
   ln -s /sys/class/leds/act_red/brightness  /var/platform/led_act_red
   ln -s /sys/class/leds/apl_green/brightness  /var/platform/led_apl_green
   ln -s /sys/class/leds/apl_red/brightness  /var/platform/led_apl_red
   ln -s /sys/class/leds/bt_blue/brightness  /var/platform/led_bt_blue
   ln -s /sys/class/leds/bt_red/brightness  /var/platform/led_bt_red
   ln -s /sys/class/leds/lte_red/brightness  /var/platform/led_lte_red

   ...
