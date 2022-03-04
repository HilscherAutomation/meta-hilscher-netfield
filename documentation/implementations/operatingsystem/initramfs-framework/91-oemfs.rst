=====================================================================
Mounting a RootFS overlay filesystem of brandlabeled data (**oemfs**)
=====================================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-oemfs*

Script
   *oemfs*

----

This script is intended to customize/brand a |project_name| OEM-base-image.
This is done in use of a signed vendor specific squashfs image located on the currently used *bootdev*.
By mounting this images file as an overlayfs over the rootfs,
all settings and/or software packages can be modified, added or removed.

.. Note::
   The *bootdevice* is the partition where the currently used *boot.cfg* file or the *rootfs* is located.

.. graphviz::
   :align: center
   :caption: Flowchart: **oemfs**

   digraph flowchart_oemfs {
      graph [href="#" target="_parent"]
      node [shape=rect width=0 height=0 margin="0.01,0.01" fontsize=8];
      edge [fontsize=8];

      Start [shape=oval, color=gold, style=filled]
      Start -> a1

      //a0 [label="mount bootdev"]
      //a0 -> a1

      a1 [label="oem directory exists\non bootdev?", shape=diamond]  
      a1 -> a2 [label="yes"]
      a1 -> End [label="no"]

      a2 [label="*-image-oem-* file exists\nin oem directory?", shape=diamond]  
      a2 -> a3 [label="yes"]
      a2 -> End [label="no"]

      a3 [label="assign the last image file to 'f'", xlabel="file=[*-image-oem-*]"]
      a3 -> a4

      a4 [label="verify image file 'f''", shape=diamond]
      a4 -> a5 [label="ok"]
      a4 -> End[label="failed", color=red, fontcolor=red]

      a5 [label="mount 'f' as\nrootfs oem overlay", style="filled"]
      a5 -> End

      //a6 [label="umount bootdev"]
      //a6 -> End

      End [shape=oval, color=gold, style=filled] 
   }
