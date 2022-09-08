========================
Chain of Trust
========================

.. :Author: Sebastian Döll <sdoell@hilscher.com>

Overview of the COT
-------------------

One of of the netFIELD OS core requirements is a secure environment and runtime. All the :ref:`security aspects<security>` during runtime rely on a *Chain Of Trust*. The COT is a sequence of verification processes, which starts at the very first place with a *Root Of Trust*. Only a valid COT guarantees a trustworthy authentication or validation during runtime. All these validation processes rely on the principle and usage of X.509 certificates and the verification of digital signatures based on asymmetric cryptography. 

Currently the netFIELD OS'S COT is limited to the use of the *Root of Trust* as verification base and thereby by a single private key per platform. By default the following components are signed by this private key and can be verified by it's public component:

* bootloader (in case HAB is supported and enabled)
* boot scripts
* FIT Image
* root file system (squashfs)
* device data
* user data (optional)

The build process requires the following variables to be setup to automatically sign the above noted components and distribute all required information which are required for verification purposes during runtime.

================================ ==========================================================================================================================
Name                             Description                                                                                                     
================================ ==========================================================================================================================
``SIGN_WRAPPER_MODE``            Set to the type of key reference.
``$PLATFORM_KEYDIR``             Set to path or reference base of the private key given by ``$PLATFORM_KEYNAME`` ($SIGN_WRAPPER_KEY_SRC=$PLATFORM_KEYDIR)
``$PLATFORM_KEYNAME``            Set to the key reference which should be used for signing of the elements of the COT (=$PLATFORM_KEYNAME).
================================ ==========================================================================================================================

For detailed information about the variable setup, the signing process and how to verify signed objects refer to :doc:`Signing and Verification<signing_and_verification>`.

The public key component will be automatically derived from the given private key and published in the ${DEPLOY_DIR_IMAGE}/key_store/${PLATFORM_KEYNAME}/${PLATFORM_KEYNAME}.pub. For verification processes during runtime the public key will be found under ``/proc/sys/srm/owner-cert``. For information how to use it and verify data during runtime refer to :doc:`Signing and Verification<signing_and_verification>`.

The following gives an overview of the currently supported key hierarchy of a netFIELD OS and it's build system.

.. graphviz::
	:align: center
	:caption: Flowchart: Key Hierarchy
   
	digraph foo1 {
		//size = "15,2";

		//graph [autoscale = true];
		//node [autoscale = true, fontsize = 5];
		//edge [autoscale = true, fontsize = 5];

		//click [label="Enlarge by open in new tab", href="#"];
      
		Start [ label = "Platform Key" ]
		a1 [ label = "Bootloader", tooltip=""];
		a2 [ label = "Boot Scripts", tooltip=""];
		a3 [ label = "FIT Image", tooltip=""];
		a4 [ label = "Root File System (squahs)", tooltip=""];
		a5 [ label = "Device Data", tooltip=""];
        a6 [ label = "(optional) User Data", tooltip=""];

		Start -> a1
		Start -> a2 [ label = "" ];
		Start -> a3 [ label = "" ];
		Start -> a4 [ label = "" ];
		Start -> a5 [ label = "" ];
		Start -> a6 [ label = "" ];
	}


The chart *Chain of Trust* shows the verification chain and it's failure handling. The initial software verification step is optional and depends on the hardware. 

.. Note:: Even though netFIELD OS provides verified boot including a verification of the read only partition of the root file system, to guarantee a safe environment the user need to make sure to protect the device from unprivileged access via appropriate account properties and password strength.

.. _cot:
.. graphviz::
	:align: center
	:caption: Flowchart: Chain of Trust
   
	digraph foo1 {
		//size = "15,2";

		//graph [autoscale = true];
		//node [autoscale = true, fontsize = 5];
		//edge [autoscale = true, fontsize = 5];

		//click [label="Enlarge by open in new tab", href="#"];
      
		Start [ label = "Power on" ]
		a1 [ label = "Optional: Initial software verification", shape="diamond", tooltip=""];
		a2 [ label = "Start bootloader", shape="rect", tooltip=""];
		a3 [ label = "Bootscript verification", shape="diamond", tooltip=""];
		a4 [ label = "Run boot script", shape="rect", tooltip=""];
		a5 [ label = "Image verification", shape="diamond", tooltip=""];
		a6 [ label = "Start image", shape="rect", tooltip=""];
		a7 [ label = "squahs fs verification", shape="diamond", tooltip=""];
		a8 [ label = "Mount root file system", shape="rect", tooltip=""];
		a9 [ label = "Deice data verfication", shape="diamond", tooltip=""];
		a10 [ label = "Publish device data", shape="rect", tooltip=""];
		b1 [ label = "Stop boot", shape="rect", tooltip=""];
		b2 [ label = "Mark as not verified", shape="rect", tooltip=""];
		End [ label = "netFIELD OS up and in a secure running state", tooltip=""];

		Start -> a1
		a1 -> a2 [ label = "OK" ];
		a2 -> a3 [ label = "OK" ];
		a3 -> a4 [ label = "OK" ];
		a4 -> a5 [ label = "OK" ];
		a5 -> a6 [ label = "OK" ];
		a6 -> a7 [ label = "OK" ];
		a7 -> a8 [ label = "OK" ];
		a8 -> a9 [ label = "OK" ];
		a9 -> a10 [ label = "OK" ];
		a10 -> End [ label = "" ];
		a1 -> b1 [ label = "Failed" ];
		a3 -> b1 [ label = "Failed" ];
		a5 -> b1 [ label = "Failed" ];
		a7 -> b1 [ label = "Failed" ];
		a9 -> b2 [ label = "Failed" ];
	}

