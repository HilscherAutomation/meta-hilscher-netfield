========
fastboot
========

.. :Author: Sebastian Döll <sdoell@hilscher.com>

Fastboot [1]_ [2]_ [3]_ is a tool as part of the Android SDK which allows formatting, deleting or writing new images to disk at low level like u-boot. The Fastboot tool may help to recover a non-bootable device. How to enter the fastboot mode refer to :doc:`Bootmenu<bootmenu>`. Depending on the needs either a single partition can be rewritten or the whole disk image. E.g. in case the device is neither able to boot the netFIELD OS nor the rescue image it might be necessary to rewrite the whole disk image.

**Pre-Requisites:**

* | A valid and bootable Bootloader on the device (a device with a corrupt bootloader image cannot be recovered)
* | DHCP Server (e.g. tftpd)
* | Android Fastboot Tools (with udp support) [2]_
  | **NOTE:** *It is recommended to download the latest Fastboot version from Android to make sure to have access to all features (e.g. Fastboot via UDP).*


..
	 :ref:`Bootmenu<boot_menu>`


How to flash/recover a device:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

On host side run the following commands

.. Note:: Flashing or erasing the GPT or any partition may delete user data or make it inaccessible. Fastboot should only be used if you know what you are doing!

.. code-block:: bash
	:linenos:
	:caption: Example how to use Fastboot

	fastboot -s udp:<ip> flash gpt <image.gpt.fastboot>
	fastboot -s udp:<ip> erase boot
	fastboot -s udp:<ip> -S 64M flash boot <image.boot.fastboot>
	fastboot -s udp:<ip> erase rescue
	fastboot -s udp:<ip> -S 64M flash rescue <image.rescue.fastboot>
	fastboot -s udp:<ip> erase system
	fastboot -s udp:<ip> -S 64M flash system <image.system.fastboot>
	fastboot -s udp:<ip> reboot


The build environment provides as well a simple script *'deploy-fastboot'* (within *$DEPLOY_DIR_IMAGE*) which allows to straightforwardly recover a device. Make sure to run the script within the folder containing all referenced Fastboot images listed below.

- \*.gpt.raw.fastboot
- \*.boot.raw.fastboot
- \*.rescue.sparse.fastboot
- \*.system.sparse.fastboot

.. code-block:: bash
	:linenos:
	:caption: Example how to use Fastboot script

	deploy-fastboot 192.168.0.10



	
.. [1] `Android Download Center <https://developer.android.com/studio#downloads>`_
.. [2] `Android Platform Tools <https://developer.android.com/studio/releases/platform-tools>`_
.. [3] `Information about the Fastboot tool <https://android.googlesource.com/platform/system/core/+/master/fastboot/#fastboot>`_

