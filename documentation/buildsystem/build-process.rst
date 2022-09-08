=============
Build Process
=============

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

The |project_name| is based on the |yocto-project| and consists of a variety of public and Hilscher specific meta-layers.
To simplify the initialization of the build environment, another dedicated |project_name| specific manifest repository is provided.
This can be used together with a so called *repo* tool to check out all required source repositories in the predetermined version.


Preparations
============

#. Installing *repo* tool

   .. code-block:: bash

      $ sudo apt-get update
      $ sudo apt-get install repo

   .. seealso::
      | https://source.android.com/setup/develop#installing-repo
      | https://source.android.com/setup/develop/repo

#. Creating a project directory

   .. code-block:: bash

      $ mkdir -p <project-directory>
      $ cd <project-directory>

#. Initializing *repo* based |project_name| project ...

   .. code-block:: bash

      $ repo init -u https://bitbucket.hilscher.com/scm/netfieldos/meta-hilscher-netfield-repo.git [-m dunfell.xml]

   Example of checking optionally the *repo* initialization ...
      .. code-block:: bash

         $ repo info
         Manifest branch: dunfell
         Manifest merge branch: refs/heads/dunfell
         Manifest groups: all,-notdefault
         ----------------------------
         $

#. Checking out / Synchronizing *repo* based |project_name| project

   .. code-block:: bash
   
      $ repo sync
      Fetching: 100% (18/18), done in 20.053s
      Garbage collecting: 100% (18/18), done in 0.266s
      Checking out: 100% (18/18), done in 1.014s
      repo sync has finished successfully.
      $

   .. note::
      This command can also be used for updating (synchronizing) the local |project_name| source repositories.

   Example of |project_name| directory structure ...
      .. code-block:: bash
      
         $ ls -l
         total 72
         lrwxrwxrwx  1 dummy dummy   49 May 17 15:10 build_all.sh -> meta-hilscher-netfield/scripts/build/build_all.sh
         drwxrwxr-x 10 dummy dummy 4096 May 17 15:07 meta-bsp-imx8mm
         drwxrwxr-x 13 dummy dummy 4096 May 17 15:07 meta-clang
         drwxrwxr-x 21 dummy dummy 4096 May 17 15:07 meta-freescale
         drwxrwxr-x 10 dummy dummy 4096 May 17 15:07 meta-gplv2
         drwxrwxr-x  6 dummy dummy 4096 May 17 15:07 meta-hilscher-boards
         drwxrwxr-x 23 dummy dummy 4096 May 17 15:07 meta-hilscher-netfield
         drwxrwxr-x 14 dummy dummy 4096 May 17 15:07 meta-hilscher-netfield-imx8
         drwxrwxr-x 14 dummy dummy 4096 May 17 15:07 meta-hilscher-netfield-intel
         drwxrwxr-x  9 dummy dummy 4096 May 17 15:07 meta-hilscher-netfield-netx4000
         drwxrwxr-x  9 dummy dummy 4096 May 17 15:07 meta-hilscher-netfield-raspberrypi
         drwxrwxr-x  9 dummy dummy 4096 May 17 15:07 meta-hilscher-netx4000
         drwxrwxr-x 18 dummy dummy 4096 May 17 15:07 meta-intel
         drwxrwxr-x 13 dummy dummy 4096 May 17 15:07 meta-openembedded
         drwxrwxr-x 17 dummy dummy 4096 May 17 15:07 meta-raspberrypi
         drwxrwxr-x 10 dummy dummy 4096 May 17 15:07 meta-rust
         drwxrwxr-x 19 dummy dummy 4096 May 17 15:07 meta-security
         drwxrwxr-x  9 dummy dummy 4096 May 17 15:07 meta-swupdate
         drwxrwxr-x 11 dummy dummy 4096 May 17 15:07 poky
         lrwxrwxrwx  1 dummy dummy   49 May 17 15:10 start_dockerenv.sh -> meta-hilscher-netfield/scripts/start_dockerenv.sh
         lrwxrwxrwx  1 dummy dummy   48 May 17 15:10 test_all.sh -> meta-hilscher-netfield/scripts/build/test_all.sh
         $
      
Building a |project_name| image
===============================

The easiest way to build and test a |project_name| image is to use the provided docker environment,
which fulfills all requirements to the build-machine (host).

.. code-block::

   $ ./start_dockerenv.sh

.. note::
   If the docker environment is not used, some additional prerequisites for using the |yocto-project|
   need to be installed on your build machine's (host) native operating system.
   
Building ...
------------

| Building an |project_name| image can be done in two ways, manually using the yoctos cmdline tool *bitbake* or using a special provided *build_all.sh* script.
| Both methods are described below ...

Building automated by *build_all.sh*
------------------------------------

The *build_all.sh* encapsulates the initialization of the build environment, the creation of a build-directory
and the building of |project_name| images for one or more hardware machines (platforms) itself into a single script call.

Example of displaying the help information of *build_all.sh* script ...
   .. code-block:: bash
   
      $ ./build_all.sh -h
      Usage: ./build_all.sh [OPTION] ...
      
      By default, a default image will be build for a predefined list of machines(platforms).
      
        -b <build_dir>              Basename of build directory which will be extended by parts of machine layer. (default: "build")
        -c                          Enable CVE check
        -d <deploy_dir>             Deploy directory (default: "dist")
        -D                          Build a debug image
        -e <extra_image_features>   Add extra image features
        -f <fw_version>             Firmware version (default: "2.4.0.0")
        -i <image>                  Image name to build (default: "netfield-image" or "netfield-image-oem-all" on oem capable machines)
        -p <extra_image_packages>   Add extra image packages
        -P <machine[0..n]>          Space seperated list of machines/platforms to build
        -s <fw_suffix>              Suffix used for firmware version
        -t                          Enable testability
      
        Examples:
          PLATFORMS="niot-e-tijcx-gb netfield-iolink-edge-gw-rev2" ./build_all.sh -t -D
          ./build_all.sh -t -D -P "niot-e-tijcx-gb netfield-iolink-edge-gw-rev2"
      
        Note:
          Each machine declaration may optionally contain an IP address of DUT (e.g."netfield-iolink-edge-gw-rev2:10.13.4.248").
          These addresses will be ignored by build process.
      
      $

Building a predefined |project_name| image for a given hardware machine (platform) ...
   .. code-block:: bash

      $ ./build_all.sh -P "<MACHINE(s)>" -D -t

   See description: :term:`MACHINE`

   .. note::
      | The resulting images can be found in the loacation which can be specifyied by the parameter ``-d <deploy_dir>``.
      | This will be defaults by the *build_all.sh* script to the *dist* directory of the project root.
      |
      | **Example**: *dist/<machine>/<image>/<firmware_version>/...*


Building manually by *bitbake*
------------------------------

Initializing the yocto build environment ...
   .. code-block:: bash

      $ TEMPLATECONF="<xxx>" . poky/oe-init-build-env <BUILD_DIRECTORY>

   See description: :term:`BUILD_DIRECTORY`, :term:`TEMPLATECONF`

Populating the remaining things not copied by the previous initialization step into the yocto build environment ...
   .. code-block:: bash

      $ for f in $(find $(cat conf/templateconf.cfg) -name *.sample$!); do cp $f conf/$(basename ${f%.*}); done

Specifying the mandatory ``FIRMWARE_VERSION`` ...
   .. code-block::
  
      echo "FIRMWARE_VERSION = <a.b.c.d[.debug]>" >> conf/local.overrides.conf
     
   .. admonition:: Alternatively

      If an environment variable ``FIRMWARE_VERSION`` is added to a whitelist,
      it can then be passed to and used by the yocto build process.

      .. code-block:: bash
       
         BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE FIRMWARE_VERSION"
      
If desired, specifying a directory where all build results will be stored ...
   .. code-block::
  
      echo "HILSCHER_DEPLOY_ROOT_DIR = <deploy_dir>" >> conf/local.overrides.conf

   .. admonition:: Alternatively

      If an environment variable ``HILSCHER_DEPLOY_ROOT_DIR`` is added to a whitelist,
      it can then be passed to and used by the yocto build process.

      .. code-block:: bash
      
         BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE HILSCHER_DEPLOY_ROOT_DIR"

   .. note::
      If not specified, ``HILSCHER_DEPLOY_ROOT_DIR`` defaults by *hilscher_image_types.bbclass* to *${DEPLOY_DIR}/dist*.

If desired, enabling the testability ...
  .. code-block::
  
     echo "include local.overrides.test.conf" >> conf/local.overrides.conf

Building a given |project_name| image  for a given hardware machine (platform) ...
   .. code-block:: bash

      $ MACHINE="<xxx>" bitbake <IMAGE>

   .. admonition:: Alternatively

      Passing the additional environment variables described above to the yocto build process.
         
      .. code-block:: bash
      
         $ MACHINE="<xxx>" HILSCHER_DEPLOY_DIR="<xxx>" FIRMWARE_VERSION="<xxx>" bitbake <IMAGE>

   See description: :term:`FIRMWARE_VERSION`, :term:`HILSCHER_DEPLOY_ROOT_DIR`, :term:`IMAGE`, :term:`MACHINE`

Testing a |project_name| image
==============================

.. note::
   |project_name| image test can only be done in cases where the testability was enabled when building the image! 

The easiest way to build and test a |project_name| image is to use the provided docker environment,
which fulfills all requirements to the build-machine (host).

.. code-block::

   $ ./start_dockerenv.sh

.. note::
   If the docker environment is not used, some additional prerequisites for using the |yocto-project|
   need to be installed on your build machine's (host) native operating system.


Testing ...
-----------

| Like building a |project_name| image, there is also a manual way with the yocto cmdline tool *bitbake*
  and a script based way by calling the script *test_all.sh*.
| Both methode are described below ...


Testing automated by *test.sh*
------------------------------

As with the *build_all.sh* the *test_all.sh* also encapsulates the initialization of the build environment
as well as the testing of the last built |project_name| images for one or more hardware machines (platforms) itself into a single script call.

Example of displaying the help information of *test_all.sh* script ...
   .. code-block:: bash
   
      $ ./test_all.sh -h
      Usage: ./test_all.sh [OPTION] ...
      
        -b <build_dir>              Basename of build directory which will be extended by parts of machine layer. (default: "build")
        -i <image>                  Image name to test (default: "netfield-image" or "netfield-image-oem" on oem capable machines)
        -P <machine[0..n]>          Space seperated list of machines/platforms to test
      
        Examples:
          PLATFORMS="niot-e-tijcx-gb:10.13.4.246 netfield-iolink-edge-gw-rev2:10.13.4.248" ./test_all.sh
          ./test_all.sh -P "niot-e-tijcx-gb:10.13.4.246 netfield-iolink-edge-gw-rev2:10.13.4.248"
      
        Note:
          Each machine declaration must contain an IP address of DUT (e.g."netfield-iolink-edge-gw-rev2:10.13.4.248").
      
      $

Testing the last built |project_name| image for the given hardware machine (platform) ...
   .. code-block:: bash

      $ ./test_all.sh -P "<MACHINE>:<TEST_TARGET_IP>"

   See description: :term:`MACHINE`, :term:`TEST_TARGET_IP`


Testing manually by *bitbake*
-----------------------------

Initializing the yocto build environment ...
   .. code-block:: bash

      $ TEMPLATECONF="<xxx>" . poky/oe-init-build-env <BUILD_DIRECTORY>

   See description: :term:`BUILD_DIRECTORY`, :term:`TEMPLATECONF`

Specifying the mandatory ``TEST_TARGET_IP`` ...
   .. code-block::
  
      sed -i 's,\(^TEST_TARGET_IP\).*,\1 ?= <a.b.c.d>,' conf/local.overrides.test.conf
     
   .. admonition:: Alternatively

      If an environment variable ``TEST_TARGET_IP`` is added to a whitelist,
      it can then be passed to and used by the yocto build process.

      .. code-block:: bash
       
         BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE TEST_TARGET_IP"
   
Testing the last built |project_name| image on the given hardware machine (platform) ...
   .. code-block:: bash

      $ MACHINE="<xxx>" bitbake <IMAGE> -c testimage

   .. admonition:: Alternatively

      Passing the additional environment variables described above to the yocto build process.
         
      .. code-block:: bash
      
         $ MACHINE="<xxx>" TEST_TARGET_IP="<xxx>" bitbake <IMAGE> -c testimage

   See description: :term:`IMAGE`, :term:`MACHINE`, :term:`TEST_TARGET_IP`


.. |yocto-project| raw:: html

   <a href="https://www.yoctoproject.org" target="_blank">Yocto Project (YP)</a>
