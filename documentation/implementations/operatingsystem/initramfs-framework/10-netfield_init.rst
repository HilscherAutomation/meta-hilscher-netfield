================================================
Preparing the |project_name| (**netfield-init**)
================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-netfield-init*

Script
   *netfield_init*

----

| The netfield_init script is common to all |project_name| and is intended to prepare the system.
| This includes the following tasks ...

.. contents::
   :local:
   :backlinks: top
   :depth: 1
   
load_kernel_modules
===================

Load modules independently of a later usage in initramfs. These modules are defaults for all |project_name| systems and may also be used by the runtime rootfs.

.. Note::
   Maybe a kernel module (even one those listed here) is (re-)loaded later in an other script of the initramfs-framework.

``pub-key-loader``
   This kernel module provides a kernel builtin public key in */proc/sys/srm/owner-cert*.

   .. Note::
      This key is used and copied by the *device_data* script.

``device-data``
   | This kernel module provides a way to export securely read-only data via */sys/device_data* to the runtime rootfs.
   | See ":ref:`initramfs_device_data`" for more informations.

..   | See :ref:`implementations/initramfs-framework/15-device_data:device_data` for more informations.
   
``efivarfs``
   This kernel module provides support for the **E**\xtensible-**F**\irmware-**I**\nterface (EFI) variables.

      
check_filesystems
=================

All existing file systems, labeled with *system*, *data* or *backup*, are checked and automatically repaired in case of erroneous.

.. Note::
   Currently only *ext2*, *ext3* and *ext4* filesystems are supported.

mount_filesystems
=================

The following filesystems are common requirements of the |project_name| and will therefore be mounted in this section.

*/run*
   A tmpfs is mounted on this mount point. This is currently the location for additional mount points
   used for the OEM RootFS overlay image or other directory overlays.
   This mount point will later also be moved/provided to the runtime RootFS.

*/var/platfrom*
   A tmpfs is mounted on this mount point, which can be filled with device-specific things.
   This mount point will later also be moved/provided to the runtime RootFS.

*/tmp*
   A tmpfs with an upper size limit of 80% (default: 50%) RAM is mounted on this mount point.
   This extended limit may be necessary to support large initrd-api files like those used by firmware recovery.


boot_cfg (handle_bootparams)
============================

As the |project_name| supports dual-boot capability, multiple kernels/fitImages and RootFS images may exists on the system partition.
In order to provide the required information about the desired boot configuration to the initramfs-framework, some boot-options/-parameters must be handed over.
This is normally done by the kernel *cmdline* where kernel as well as initramfs related configurations can be configured.
For simplifying and shrinking the kernel *cmdline*, an alternative way is implemented.
A so called signed *boot.cfg* file can be used to specify parameters line by line, which do not necessarily have to be in the kernel *cmdline*.
The code segment described here is intended to verify such an optional *boot.cfg* file and, if available,
to parse and translate their contents into ``bootparam_XXX`` environment variables.
All configured parameters contained exclusively in the *boot.cfg* file will be provided as ``bootparam_<key>=<value>``
whereas previously parameters configured by the kernel *cmdline* will be kept, even an empty string was set!

   .. code-block:: bash
      :linenos:
      :caption: Example: **boot.cfg** file

      description='hilscher-rescue-image - 2.0.0.0.debug'
      kernel='bzImage'
      root='hilscher-rescue-image-niot-e-tijcx-gb-2.0.0.0.debug-20210113145248.rootfs.squashfs'
      overlaytargets='etc home opt var/lib var/log usr/local'

   .. code-block:: bash
      :linenos:
      :caption: Example: Resulting **bootparam_XXX** environment

      bootparam_description='hilscher-rescue-image - 2.0.0.0.debug'
      bootparam_kernel='bzImage'
      bootparam_root='hilscher-rescue-image-niot-e-tijcx-gb-2.0.0.0.debug-20210113145248.rootfs.squashfs'
      bootparam_overlaytargets='etc home opt var/lib var/log usr/local'

   .. Note::
      | Some parameters are only descriptive parameters and are not used to configure the image to be booted.
      | An example is the ``description`` parameter, which is only used in the boot menu of bootloader
        to name the image to be loaded in human-readable terms.

The boot-options/-parameters used by the initramfs-framework of |project_name| are ...
   ============================== ========= =================================
   Parameters/Variables           Mandatory Value source selection hierarchy
   ============================== ========= =================================
   ``[bootparam_]bootCfg``        no        kernel *cmdline*
   ``[bootparam_]root``           yes       kernel *cmdline*, *boot.cfg* file
   ``[bootparam_]rootfstype``     no        kernel *cmdline*, *boot.cfg* file
   ``[bootparam_]rootflags``      no        kernel *cmdline*, *boot.cfg* file
   ``[bootparam_]overlay``        no        kernel *cmdline*, *boot.cfg* file
   ``[bootparam_]overlayfstype``  no        kernel *cmdline*, *boot.cfg* file
   ``[bootparam_}overlayflags``   no        kernel *cmdline*, *boot.cfg* file
   ``[bootparam_]overlaytargets`` no        kernel *cmdline*, *boot.cfg* file
   ============================== ========= =================================

bootparam_bootCfg
-----------------

To enable the alternative possibility of influencing the *bootparams*, the parameter ``bootCfg`` must be specified in the kernel *cmdline*.
If so, its value is treated as a signed *boot.cfg* file, which is parsed and translated into appropriate ``bootparam_XXX`` variables.

.. graphviz::
   :align: center
   :caption: Flowchart: Handle *boot.cfg* file

   digraph flowchart_handle_boot_cfg {
      graph [href="#" target="_parent"]
      node [shape=rect width=0 height=0 margin="0.01,0.01" fontsize=8];
      edge [fontsize=8];

      r1 [label = "translate an optional given LABEL into its real block device"];
      r2 [label = "mount the block device"];
      r3 [label = "parse and translate\ninto bootparam_XXX\nvariables"];

      d1 [label = "bootCfg\nconfigured?"];
      d2 [label = "block device\navailable?"];
      d3 [label = "verify signed\nboot.cfg file"];

      d1,d2,d3 [shape=diamond]
      Start,End [shape=oval color=gold style=filled]
      Error [label="Error:\nSystem freeze!" shape=oval color=red style=filled]

      Start -> d1
      d1 -> End  [label="no"];
      d1 -> r1 [label="yes"];
      r1 -> d2;
      d2 -> d2 [label="wait" fontcolor=red];
      d2 -> r2 [label="yes"];
      r2 -> d3;
      d3 -> Error [label="failed" fontcolor=red];
      d3 -> r3 [label="ok"];
      r3 -> End;
   }

``bootparam_bootCfg``
   .. code-block::

      Usage: bootCfg=path_to_boot_cfg

      path_to_boot_cfg
         Specify the path to an optional signed boot.cfg file. This can be done directly (bootCfG=/dev/mmcblk1p3/boot.cfg) or via a label (bootCfg=LABEL=system/boot.cfg).

   .. code-block::
      :linenos:
      :caption: Example: kernel **cmdline** (*netfield-compact-x8m-rev1*)

      console=ttymxc2,115200 earlycon=ec_imx6q,0x30880000,115200 bootCfg=/dev/mmcblk1p3/boot.cfg rootwait rw rootdelay=1 roottimeout=10 loglevel=7


bootparam_rootXXX
-----------------

In order to boot the desired |project_name| system, the parameters shown below are required.
These includes the RootFS itself and some other parameters related to filesystem type and mount flags.
All these parameters can be provided by the kernel *cmdline* and/or by a separate *boot.cfg* file.
The task of this code section is to check these and some additional parameters for availability and,
if not specified, to attempt to automatically resolve them in use of the mandatory ``bootparam_root`` parameter.

``bootparam_root``
   .. code-block::

      Usage: root='name<.fstype>'

      name
         The name specify the RootFS to boot.
         It can be a block device or an image file.

      fstype
         The optional fstype may overrides a undefined ``bootparam_rootfstype``.

   .. Attention::
      - In case of missed ``bootparam_root``, the system freeze!

``bootparam_rootfstype``
   .. code-block::

      Usage: rootfstype='type'

      type
         Specify the filesystem type of rootfs.

``bootparam_rootflags``
   .. code-block::

      Usage: rootfsflags='flags'

      flags
         Specify additional mountflags used to mount the rootfs.

bootparam_overlayXXX
--------------------

| To enable writable locations within a readonly rootfs, it is possible to specify overlay filesystems.
| These can be configured by the ``bootparam_overlayXXX`` in the kernel *cmdline* and/or by a seperate *boot.cfg* file.
| See ":ref:`initramfs_overlayfs`" for more informations.

.. | See :ref:`implementations/initramfs-framework/94-overlayfs:overlayfs` for more informations.

``bootparam_overlay``
   .. code-block::

      Usage: overlay='name'

      name
         The name specify the writeable storage used by the overlay filesystem.
         

   .. Note::
      If required and not specified, this defaults to */dev/mapper/data-data*.

``bootparam_overlayfstype``
   .. code-block::

      Uage: overlayfstype='type'

      type
         Specify the filesystem type used by the writeable storage of overlay filesystem.

``bootparam_overlayflags``
   .. code-block::

      Usage: overlayflags='flags'
   
      flags
         Specify additional mountflags used to mount the writeable storage of overlay filesystem.

``bootparam_overlaytargets``
   .. code-block::

      Usage: overlaytargets='targets'

      targets
         Specify a list of space separated targets that are should overlapped by overlay filesystems.
         This list can be both, an entire RootFS as well as individual directories.
