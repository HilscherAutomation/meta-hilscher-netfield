====================================================================
Secure API for executing an arbitrary external code (**initrd_api**)
====================================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-initrd-api*

Script
   *initrd_api*

----

The *initrd_api* script provides a secure API to run an arbitrary code.
This code may consists of multiple script files, binaries or everything else.
All these components are archived into a single signed *initrd-api* file.
This *initrd_api* script search on used *bootdevice* for such API files
and handle these in case of success.

.. Note::
   The *bootdevice* is the partition where the currently used *boot.cfg* file or the *rootfs* is located.

.. graphviz::
   :align: center
   :caption: Flowchart: **initrd_api**

   digraph flowchart_initrd_api {
      graph [href="#" target="_parent"]
      node [shape=rect width=0 height=0 margin="0.01,0.01" fontsize=8];
      edge [fontsize=8];
   
      Start [shape=oval, color=gold, style=filled]
      Start -> a0

      a0 [label="mount bootdev"]
      a0 -> a1

      a1 [label="assign the first/next file to 'f'", xlabel="file=[initrd-api-*]"]
      a1 -> a3

      a3 [label="verify signed 'f''", shape=diamond]
      a3 -> a4 [label="ok"]
      a3 -> a6[label="failed", color=red, fontcolor=red]

      a4 [label="extract\napi-file 'f'", style="filled"]
      a4 -> a5

      a5 [label="execute\nrunscript.sh", style="filled"]
      a5 -> a6
      
      a6 [label="is 'f' the last file?", shape=diamond]
      a6 -> a1 [label="no"]
      a6 -> a7 [label="yes"] 

      a7 [label="umount bootdev"]
      a7 -> End

      End [shape=oval, color=gold, style=filled] 
   }
