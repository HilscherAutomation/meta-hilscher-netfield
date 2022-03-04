========================
Signing and Verification
========================

.. :Author: Sebastian Döll <sdoell@hilscher.com>

As noted under :doc:`Chain of Trust<cot>` the netFIELD OS relies on the use of one private key per platform to sign all elements in the chain. The build system uses the :ref:`sign-wrapper.bbclass<sign_wrapper_class>` for the key handling and signing processes.


.. _sign_wrapper_class:

The sign wrapper class
^^^^^^^^^^^^^^^^^^^^^^

The build environment automatically signs all components of the :doc:`COT<cot>` and extracts all required information from the given private key and provides it to the required components to be able to verify a signed component during runtime. How to sign custom data is explained in the following. 

The class can process private keys in the two forms:

* local file reference
* object reference of a key of an PKCS11 interface

The class offers the following functions:

* | signing a given object
  | **openssl_sign_wrapper [reference of the key to use] [checksum] [file to sign]**
  
* | extracting and publishing the public key derived from a given private key
  | **populate_public_key [reference of the key to use]**

When calling a class's function, additionally the following variables need to be setup. These variables describe the type and required properties of the referenced key.

================================ ============================== ================================================================================================================
Name                             Value                              Description                                                                                                     
================================ ============================== ================================================================================================================
``SIGN_WRAPPER_MODE``            | "file"                       | *file*   => the key referenced in the function call is stored in a local file
                                 | "PKCS11"                     | *PKCS11* => the key referenced in the function call is is kept on a PKCS11 compatible device
``SIGN_WRAPPER_KEY_SRC``         | String / default             | Path or reference base of the private key given in the function call
                                 | value=``$PLATFORM_KEYDIR``   | 
                                                                | e.g. mode = *file*:                                          
                                                                | /my_project_folder/all_my_platform_keys/
                                                                |                                                                                                                                                                                              
                                                                | e.g. mode = *PKCS11*:                                                                                           
                                                                | PKCS11:token=[token-name];object=[object-name]
``SIGN_WRAPPER_PKCS11_PIN``                                     In case mode PKCS11 is used a pin may be required to access the services.
================================ ============================== ================================================================================================================

The public key component will be stored under *${DEPLOY_DIR_IMAGE}/key_store/${key-name}/{key-name}.pub*.

How to use sign_wrapper.bbclass
-------------------------------

.. code-block:: bash
	:linenos:
	:caption: Example of the variable setup in case of locally stored keys
	
	# the key is stored under:
	# /home/me/workspace/keys/my_platform.key
	# key name referenced by the function call => "my_platform"
	SIGN_WRAPPER_KEY_SRC="/home/me/workspace/keys/"
	SIGN_WRAPPER_MODE="file"
	
	# the public key will be stored under
	#${DEPLOY_DIR_IMAGE}/key_store/my_platform/my_platform.pub
	
	
.. code-block:: bash
	:linenos:
	:caption: Example of a variable setup in case of a remote signing server
	
	# key name referenced by the function call => "my_key"
	SIGN_WRAPPER_KEY_SRC="pkcs11:token=netFIELDOS;object=my_platform"
	SIGN_WRAPPER_MODE="pkcs11"
	
	# the public key will be 
	#${DEPLOY_DIR_IMAGE}/key_store/my_key/my_key.pub


.. code-block:: bash
	:linenos:
	:caption: Example how sign a file using the sign_wrapper_class.bbclass
	
	openssl_sign_wrapper [reference of the key to use] [checksum] [file to sign]
	
.. code-block:: bash
	:linenos:
	:caption: Example how publishing a public key using the sign_wrapper_class.bbclass
	
	populate_public_key [reference of the key to use]
	
Published keys will be stored in the deploy directory under *${DEPLOY_DIR_IMAGE}/key_store/${key-name}/{key-name}.pub*.


How to manually sign and verify
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This chapter describes the background information about the FIT image signing process and the bootloader. It shows for example how to manually create, sign and verify a FIT image.

.. _howto_private_key:

How to create a private key and a certificate?
----------------------------------------------

The following command will create a private key using RSA algorithm,4096bits. For more information about keys creation

.. code-block:: bash
	:linenos:
	:caption: Example how to generate private key

	openssl genpkey -algorithm RSA -out priv.key -pkeyopt rsa_keygen_bits:4096 -pkeyopt rsa_keygen_pubexp:65537


.. _howto_sig_check:

How does the u-boot signature check work like?
----------------------------------------------
The supported image type is a *FIT image* (Flattened uImage Tree). FIT is formally a flattened device tree which contains the image and further information about the image like 
the signature, a description and other detail parameter. For more information about the FIT format u-boot and kernel [#]_ [#]_.

The signed FIT binary image can be created using the mkimage tool provided by the u-boot source. As source file for all required information and parameter a simple text file 
will be used.


.. _howto_sign_fitimage:

How to sign a fitimage
----------------------

It is possible create a FIT image and sign it via the mkimage tool provided by the u-boot source.

To make the successful image verification mandatory for the boot process, it is important to use "-r" to mark the key and therefore the successful verification as required.

.. code-block:: bash
	:linenos:
	:caption: Example how to sign a file´
	
	# mkimage -f [path to its file] -k [path/dir to private key referenced in ITS file] -K [path to dtb where to store public key] -r [path to resulting FIT image]
	# e.g.
	mkimage -f ./fit-format.its -k ./keys/ -K ./u-boot.dtb -r fitimage


.. code-block:: c
	:linenos:
	:caption: Example Layout of an ITS file
	
	/dts-v1/;
	/ {
		description = "firmware-itb";
		#address-cells = <1>;
		images {
			firmware {
				description = "firmwareA";
				arch = "arm";
				type = "firmware";
				os = "u-boot";
				compression = "gzip";
				load = <0x40000000>;
				entry = <0x40000000>;
				data = /incbin/([path to image]);
				hash-1 {
					algo = "sha256";
				};
			};
		};
		configurations {
			default = "conf1";
			conf1 {
				description = "default configuration";
				/* kernel is required set to image ("firmware") to include */
				kernel = "firmware";

				hash-1 {
					algo = "sha256";
				};
				signature {
					algo = "sha256,rsa4096";
					/* IMPORTANT: name the key as the file in the given key location see mkimage -K */
					key-name-hint = "priv";
					sign-images = "kernel";
				};
			};
		};
	};

.. _howto_inspect_fitimage:

How to inspect a binary FIT image
---------------------------------

The created binary image and its components can be inspected via the device tree compiler tool or with the u-boot command fdt (requires CONFIG_CMD_FDT=y).

.. code-block:: bash
	:linenos:
	:caption: Example of inspecting a FIT image

	# Dump the content of a binary FIT image to console using the device tree compiler *dtc*
	dtc -I dtb -O dts fit-image.dtb

	# Dump the content of a binary FIT image to console using the u-boot command *fdt*
	fatload mmc 0:1 [load address] fitimage
	fdt addr [load address]
	fdt list /
	fdt print /
	
	# Dump FIT image information and validate hash and signature
	fatload [mmc/usb/...] [devno]:[partno] [load address] fitimage
	imimage [load address]
	fdt addr [load address]
	fdt check



How to verify data signed with the platform key under netFIELD OS
-----------------------------------------------------------------

Some application may require the need of verifying the authenticity of data during runtime. In case you want to validate a signed file e.g. rootfs.img or the device data you can run the following:

**1. Get the public key**

.. code-block:: bash
	:linenos:
	
	openssl x509 -pubkey -in /proc/sys/srm/owner-cert -noout > pubkey

**2. Verify "file" it's signature "file.sig" with the extracted public key**

.. code-block:: bash
	:linenos:
	
	openssl dgst [-sha512] -verify pubkey -signature file.sig file
	e.g. rootfs
	openssl dgst -sha512 -verify "pubkey" -signature rootfs.img.sig rootfs.img
	
	e.g. device data
	base64 -d /sys/device_data/signature > signature
	cat /sys/device_data/raw | tr -d '\n' | openssl dgst -sha512 -verify "pubkey" -signature "signature"


Device Data
-----------


+--------------------------------+---------------------------------------------------------------------------------------------------------+
| File                           | Description                                                                                             |
+--------------------------------+---------------------------------------------------------------------------------------------------------+
| /sys/device_data/raw           | Full content in JSON format (Schema: devicelabel.json.schema, Sample: devicelabel.json)                 |
+--------------------------------+---------------------------------------------------------------------------------------------------------+
| /sys/device_data/signature     | Base-64 encoded binary signature of JSON content (algorithm RSA/SHA512)                                 |
+--------------------------------+---------------------------------------------------------------------------------------------------------+
| /sys/device_data/publickey     | Public key used for verification                                                                        |
+--------------------------------+---------------------------------------------------------------------------------------------------------+
| /sys/device_data/mac           | MAC address used for device binding (extracted from "mac" node in root of JSON)                         |
+--------------------------------+---------------------------------------------------------------------------------------------------------+
| /sys/device_data/product_name  | Decoded node of full JSON content (Name of the product)                                                 |
|                                | NOTE: All further JSON nodes will be decoded in a directory structure in the same hierarchy as in JSON. |                             
+--------------------------------+---------------------------------------------------------------------------------------------------------+



.. [#] Ausführliche Informationen zum FIT image format u-boot <https://source.denx.de/u-boot/u-boot/-/tree/master/doc/uImage.FIT>_
.. [#] Ausführliche Informationen zum FIT image format kernel <https://source.denx.de/u-boot/u-boot/-/blob/master/doc/uImage.FIT/howto.txt>_


