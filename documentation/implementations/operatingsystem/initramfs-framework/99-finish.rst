=============================================
Switching over to runtime RootFS (**finish**)
=============================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *poky/meta/recipes-core/initrdscripts/initramfs-framework_1.0.bb*

   .. seealso::
      meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-framework

Package
   *initramfs-framework-base*

Script
   *finish*

----

This script moves some required mount points to the runtime RootFS and passes this to the kernel for further booting.

.. Note::
   From this point on, the kernel boots the desired runtime RootFS (|project_name|)!
