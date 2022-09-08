========
Glossary
========

:term:`B <BUILD_DIRECTORY>` |
:term:`F <FIRMWARE_VERSION>` |
:term:`H <HILSCHER_DEPLOY_ROOT_DIR>` |
:term:`I <IMAGE>` |
:term:`T <TEMPLATECONF>`

.. glossary::

   BUILD_DIRECTORY
      | Refers a build directory used by the yocto build process.
      | If not available it will be created (Default: **build**).

   FIRMWARE_VERSION
      | Defines a firmware version to build.

   HILSCHER_DEPLOY_ROOT_DIR
      | Refers a directory where all build results will be deployed for easy accessing.

   IMAGE
      | Refers a target image name to build.
      | See ":ref:`buildsystem/supported-machines:supported machines`"

   MACHINE
      | Refers a hardware machine (platform) an image / a package will be build for.
      | See ":ref:`buildsystem/supported-machines:supported machines`"

   TEMPLATECONF
      | Refers to a sample configuration directory used by the yocto build process/environment.
      | See ":ref:`buildsystem/supported-machines:supported machines`"

   TEST_TARGET_IP
      | Defines a static IP address of a running device that will be used for the |project_name| image test.
      | See ":ref:`buildsystem/test-framework:test framework`"
