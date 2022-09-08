===================
Initramfs Framework
===================

The initramfs-framework provides an init script that is started by the kernel directly after the initramfs is mounted.
It is responsible to mount common filesystems like */proc*, */sys*, */tmp* and more.
Furthermore it provides a simple interface for including additional scripts.
This interface includes the function calls ``pre_<module>``, ``<module>_enable``, ``<module>_run``, and ``post_<module>``
as well as the storage location in */init.d*. All related modules must be conform to a numbered naming scheme like *00-macros_hooks*.
The naming order will then equal to the execution order of the scripts.

Below, all involved scripts used by the |project_name| are shown in the right execution order.

.. toctree::
   :maxdepth: 1

   00-macros_hooks
   01-udev
   09-lvm
   10-netfield_init
   11-platform_init
   12-initrd_api
   13-factory_default_reset
   14-backup_restore
   15-device_data
   16-detect_cifx
   17-provisioning
   90-rootfs
   91-oemfs
   93-update_hooks_pre_overlayfs
   94-overlayfs
   95-update_hooks_post_overlayfs
   99-finish

.. only::  subproject and html

   Indices
   =======

   * :ref:`genindex`
