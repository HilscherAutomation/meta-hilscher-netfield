.. _initramfs_update_hooks:

=======================================================================================
Processing pre overlayfs hooks used by firmware updates (**update_hook_pre_overlayfs**)
=======================================================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-update-hooks*

Script
   *update_hookl_pre_overlayfs*

----

As with the initramfs-framework itself, the update hooks (scripts) described here
are searched for in the directory */etc/update-hooks.d* and executed in a sorted order.
The API comprise currently two function calls, the ``<script_name>_preoverlay``
and the ``<script_name>_postoverlay``. The first function is called by *update_hooks_pre_overlayfs* script
before any overlay filesystem is mounted and the second function is called by *update_hooks_post_overlayfs* script
after the overlay filesystems are mounted. This allows a before and after comparison of configuration files
to take the appropriate actions that may be required by firmware updates.
All related update scripts must be conform to a numbered naming scheme like *10-updateca*.
The naming order will then equal to the execution order of the scripts.

Below, all available scripts used by the |project_name| are shown in the right execution order.

updateuser
   If required, this script merges the previously customized configuration of */rootfs/etc/passwd*, */rootfs/etc/group*
   and */rootfs/etc/shadow* into the new configuration files provided by a firmware update.
   
updateca
   If required, this script merges the previously customized configuration of */rootfs/etc/ca-certificates.conf*
   into the new configuration provided by a firmware update.

updatefstab
   If required, this script merges the previously customized */etc/fstab* configuration into the new configuration provided by a firmware update.

updateiotedge
   This script is responsible to adapt the iotedge configuration to the new requirements provided by a firmware update.
