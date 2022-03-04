==========================================
Common macros and hooks (**macros_hooks**)
==========================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-macros-hooks*

Script
   *macros_hooks*

----

This script provides a collection of *macros*, *hook-* and *module- functions*.
The *macros* are accessible global in all init scripts and the *hooks* are used before and after every module if enabled.
The *module functions* itself are currently only intended to install the *hook functions*.

.. contents::
   :local:
   :backlinks: top
   :depth: 1

Macros
======

``__msg()``
   This is a wrapper and prefixes the msg() function of the init process with the following text.
      
   .. code-block::

      ### ${module}:

``__info()``
   This is a wrapper and prefixes the info() function of the init process with the following text.

   .. code-block::

      ### ${module}:

``__debug()``
   This function is a replacement of the original ``debug()`` of the init process.
   Instead of using the variable ``bootparam_debug`` the ``bootparam_mydebug`` is used to permit the console output.
   As like the other wrapper functions, the following message is also prefixed to the debug information.

   .. code-block::

      ### ${module}:

``__fatal()``
   This is a wrapper and prefixes the fatal() function of the init process with the following text.

   .. code-block::

      ### ${module}:

``__skip()``
   This function can be used in the ``<module>_enabled()``` to print the following message to the console.

   .. code-block::

      ### Skipping ${module} ...
      ################################################################################

Hook functions
==============

If installed/enabled, these functions will run before and after each module.
They are used to frame the console messages from each module. 
This should make the debug output easier to read.

``premod()``
   This prints the following message to the console.

   .. code-block::
      
      ################################################################################
      ### Starting ${module} ...

``postmod()``
   This prints the following message to the console.

   .. code-block::

      ### Exiting ${module} ...
      ################################################################################

Module functions
================

The module functions described here are intended to install the hook functions (see above) in case of a running debug initramfs image.
Information about the image type is obtained from the version file, which may be extended with a **.debug** string.
In such a case, the variable below are defined and the hook functions will be installed.

``bootparam_init_fatal_sh = true``
   This will prompt to a shell instead of an infinite loop, when a *fatal*/*__fatal* state is reached.
      
``bootparam_mydebug = true``
   This enables installing the previously mentioned *hook functions* as well the the console output of ``__debug()`` an ``__skip()``.

| Additionally and regardless of image type the PATH variable is exported to the environment to make it globally usable.
| For example, this is required in a chroot environment such as used by initramfs-netfield-update-hooks.
