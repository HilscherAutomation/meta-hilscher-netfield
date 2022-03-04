============
Installation
============

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>


Installing via WIC-Image
========================

.. note::
   | This method can be used to install a |project_name| image with no target device requirements.
   | That means an installation from scratch without any running bootloader.

To simplify copying the last created |project_name| image, a script named *deploy-wic-bz2*
is placed in the image directory of ``HILSCHER_DEPLOY_ROOT_DIR``.
This script also performs additional checks to ensure the correct target device has been selected.

Example of displaying the help information of *deploy-wic-bz2* script ...
   .. code-block:: bash
   
      $ deploy-wic.bz2
      Usage: ./deploy-wic-bz2 DEST-DEV
      $

If a storage device like a hard disk or a sd-card is connected to the build-machine (host) this script can be easily called to write the last WIC-Image to the target device.

Example:
   .. code-block::
   
      $ ./deploy-wic-bz2 /dev/sdd
      Deploying to /dev/sdd
      image: hilscher-netfield-image-oem-netfield-niot-e-nfl90-q2n16-n-rev1-2.4.0.0-20220520152021.rootfs.wic.bz2
      [sudo] password for dummy:         
      459784192 bytes (460 MB, 438 MiB) copied, 19 s, 24,2 MB/s
      0+93836 records in
      0+93836 records out
      469294080 bytes (469 MB, 448 MiB) copied, 19,6561 s, 23,9 MB/s
      Mon May 23 18:25:51 CEST 2022
      ... done
      $

   .. admonition:: Alternatively

      Copying a |project_name| image manually to the target device.
         
      .. code-block:: bash
      
         $ bzcat <IMAGE> | sudo dd of=<DEST_DEV> bs=10M status=progress && sync

Installing via *fastboot*
=========================

.. note::
   For installing a |project_name| image on a device via *fastboot*, a working bootloader and network connection is required!

To simplify copying the last created |project_name| image via *fastboot* to the target device, a script named *deploy-fastboot*
is placed in the image directory of ``HILSCHER_DEPLOY_ROOT_DIR``.

Example of displaying the help information of *deploy-fastboot* script ...
   .. code-block:: bash

      $ ./deploy-fastboot
      Usage: ./deploy-fastboot DEST-IP
      $

If the target device is connected to a 192.168.253.0/24 LAN and it is configured to *fastboot* mode (see ":ref:`implementations/bootloader/fastboot:fastboot`"),
this script can be easily called to write the last |project_name| image to the target device.

.. note::
   The target IP-Address (``DEST-IP``) is always set to 192.168.253.1!

Example:
   .. code-block::

      $ ./deploy-fastboot 192.168.253.1
      Deploying to 192.168.253.1
      gpt image: hilscher-netfield-image-oem-netfield-niot-e-nfl90-q2n16-n-rev1-2.3.0.0.debug-20220524060007.gpt.raw.fastboot
      boot image: hilscher-netfield-image-oem-netfield-niot-e-nfl90-q2n16-n-rev1-2.3.0.0.debug-20220524060007.boot.raw.fastboot
      rescue image: hilscher-netfield-image-oem-netfield-niot-e-nfl90-q2n16-n-rev1-2.3.0.0.debug-20220524060007.rescue.sparse.fastboot
      system image: hilscher-netfield-image-oem-netfield-niot-e-nfl90-q2n16-n-rev1-2.3.0.0.debug-20220524060007.system.sparse.fastboot
      Sending 'gpt' (17 KB)                              OKAY [  0.009s]
      Writing 'gpt'                                      OKAY [  0.163s]
      Finished. Total time: 0.172s
      Erasing 'boot'                                     OKAY [  0.226s]
      Finished. Total time: 0.227s
      Sending 'boot' (65536 KB)                          OKAY [  7.192s]
      Writing 'boot'                                     OKAY [  9.655s]
      Finished. Total time: 16.848s
      Erasing 'rescue'                                   OKAY [  0.398s]
      Finished. Total time: 0.398s
      Sending 'rescue' (65505 KB)                        OKAY [  6.186s]
      Writing 'rescue'                                   OKAY [ 19.050s]
      Finished. Total time: 25.238s
      ******** Did you mean to fastboot format this ext4 partition?
      Erasing 'system'                                   OKAY [  0.759s]
      Finished. Total time: 0.760s
      Sending sparse 'system' 1/5 (65535 KB)             OKAY [  5.676s]
      Writing 'system'                                   OKAY [ 10.486s]
      Sending sparse 'system' 2/5 (60806 KB)             OKAY [  5.734s]
      Writing 'system'                                   OKAY [ 11.297s]
      Sending sparse 'system' 3/5 (65535 KB)             OKAY [  5.711s]
      Writing 'system'                                   OKAY [  9.154s]
      Sending sparse 'system' 4/5 (65535 KB)             OKAY [  5.859s]
      Writing 'system'                                   OKAY [  9.310s]
      Sending sparse 'system' 5/5 (9155 KB)              OKAY [  1.031s]
      Writing 'system'                                   OKAY [  2.136s]
      Finished. Total time: 66.397s
      Rebooting                                          OKAY [  0.000s]
      Finished. Total time: 0.000s
      Tue May 24 08:14:08 CEST 2022
      ... done
      $


