========================================
Mounting the runtime RootFS (**rootfs**)
========================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *poky/meta/recipes-core/initrdscripts/initramfs-framework_1.0.bb*

   .. seealso::
      meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-framework

Package
   *initramfs-module-rootfs*

Script
   *rootfs*

----

This is a slightly modified version of the mainline script from the *initramfs-framework*.
The modification comprises a verification of a prerequisite signed RootFS image file against the public key provided by the ``pub-key-loader`` kernel module.
In case of success the RootFS is mounted as runtime RootFS.

| See :ref:`implementations/operatingsystem/initramfs-framework/10-netfield_init:load_kernel_modules` for more informations.
| See :ref:`implementations/operatingsystem/initramfs-framework/10-netfield_init:bootparam_rootXXX` for more informations.

.. Attention::
   If the verification fails or ``bootparam_root`` not references an image file, the system freeze!
