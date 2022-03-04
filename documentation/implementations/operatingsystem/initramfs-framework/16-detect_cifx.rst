============================================================================
Retrieving detailed information about installed cifx cards (**detect_cifx**)
============================================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-detect-cifx*

Script
   *detect_cifx*

----

| This script is responsible to retrieve informations about the installed firmware of available *cifx-cards*.
| All these informations will then be provided via the files ...

Example: PCI cifx-cards
   .. code-block::

      /var/platform/cifx/pci/\*/
      |-- dev
      |-- device_number
      |-- hw_assembly
      `-- serial_number

   .. code-block::
      :caption: Example: niot-e-tijcx-gb

      root@niot-e-tijcx-gb:~# ls -l  /var/platform/cifx/pci/cifX0/dev
      lrwxrwxrwx 1 root root 88 May 12 06:27 /var/platform/cifx/pci/cifX0/dev -> /sys/devices/pci0000:00/0000:00:1c.3/0000:04:00.0/0000:05:01.0/0000:06:00.0/0000:07:00.0

      root@niot-e-tijcx-gb:~# cat /var/platform/cifx/pci/cifX0/device_number 
      1291105

      root@niot-e-tijcx-gb:~# cat /var/platform/cifx/pci/cifX0/hw_assembly   
      0x0080:Ethernet int
      0x0080:Ethernet int
      0xFFFB:I2C (PIO)
      0xFFF6:SYNC

      root@niot-e-tijcx-gb:~# cat /var/platform/cifx/pci/cifX0/serial_number 
      20650

Example: SPI cifx-cards
   .. code-block::

      /var/platform/cifx/spi/cifX\*/
      |-- dev
      |-- device_number
      |-- hw_assembly
      |-- mode
      `-- serial_number

   .. code-block::
      :caption: Example: niot-e-tpi51-en-re

      root@niot-e-tpi51-en-re:~# ls -l /var/platform/cifx/spi/cifX0/dev
      lrwxrwxrwx 1 root root 14 May 12 06:24 /var/platform/cifx/spi/cifX0/dev -> /dev/spidev0.0

      cat  /var/platform/cifx/spi/cifX0/device_number 
      7660120

      root@niot-e-tpi51-en-re:~# cat  /var/platform/cifx/spi/cifX0/hw_assembly   
      0x0080:Ethernet int
      0x0080:Ethernet int
      0x0001:unavailable
      0x0001:unavailable

      root@niot-e-tpi51-en-re:~# cat  /var/platform/cifx/spi/cifX0/mode        
      0

      root@niot-e-tpi51-en-re:~# cat  /var/platform/cifx/spi/cifX0/serial_number 
      23562
