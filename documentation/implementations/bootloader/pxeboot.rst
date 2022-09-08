========
PXE Boot
========

.. :Author: Sebastian Döll <sdoell@hilscher.com>

PXE allows to boot a operating system via network. The device will enter PXE boot mode automatically if no boot script is found (for more information refer to :ref:`boot process<builtin_boot_process>`). In case of a bricked device which does not offer :ref:`Fastboot<bootmenu_fastboot>`, this may be one way to recover the device. The PXE boot process will request a configuration file describing the boot configuration. The configuration may comprise for example information about the kernel image and boot parameter or more. For information about the syntax and supported commands refer to [1]_.

.. Note:: According to the security guide lines of the netFIELD OS, the PXE boot mode allows to boot only signed and successfully verified FIT images but it lacks a verification of the PXE configuration file.

In case the device enters PXE boot mode it will enter a loop sending DHCP request till it receives a valid response. By default the device expects all PXE required parameter to be delivered via the DHCP response.

The following parameter need to be set up by the DHCP response:

* | ``serverip``
  | IP of the server serving the PXE (configuration) file and the kernel image
* | ``bootfile``
  | Name of PXE (configuration) file

If the device received a valid DHCP response and the parameter are correctly setup, the device will start the network boot process.

.. Note:: If the parameter *serverip* is not set the PXE boot will not start. If *bootfile* is not set the PXE process will try to request various files, starting with the device's MAC address. Nevertheless it is recommended to set the parameter *bootfile*.


Example of a PXE configuration file
-----------------------------------

.. code-block:: bash
	:linenos:
	:caption: Example of a PXE configuration file

	menu title PXE Boot Example
	label NFS-Root
		kernel kernel
		append root=/dev/nfs ip=dhcp nfsroot=192.168.5.1:/srv/nfs/myroot,noatime,noac,nolock,rw,tcp,timeo=5,retrans=2 rootwait [additionl parameter]
		
	default network-boot
	timeout 100
	prompt 0

.. Note:: Make sure the scripts ends with NULL character otherwise the script length can not be correctly determined by u-boot, which will end in undefined behavior.



Overview of PXE boot process related Variables
----------------------------------------------
The following table gives an overview of all variables used by the PXE boot process. 

+--------------------+------------------------------------------------------------+
| Name               | Description                                                |
+====================+============================================================+
| ``pxefile_addr_r`` | load address of the PXE configuration file                 |
+--------------------+------------------------------------------------------------+
| ``kernel_addr_r``  | load address of the kernel                                 |
+--------------------+------------------------------------------------------------+
| ``initrd_addr_r``  | load address of initrd                                     |
+--------------------+------------------------------------------------------------+
| ``fdt_addr_r``     | load address of the device tree                            |
+--------------------+------------------------------------------------------------+
| ``bootfile``       | | name of the PXE configuration file (will be set by DHCP  |
|                    | | response)                                                |
+--------------------+------------------------------------------------------------+
| ``serverip``       | | name of the server providing the PXE file (will be set   |
|                    | | by DHCP response)                                        |
+--------------------+------------------------------------------------------------+

.. [1] `Information about PXE boot (u-boot)<https://source.denx.de/u-boot/u-boot/-/blob/master/doc/README.pxe>`
