.. _initramfs_overlayfs:

======================================================================
Mounting RootFS overlay filesystems for writeable data (**overlayfs**)
======================================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-overlayfs*

Script
   *overlayfs*

----

The *overlayfs* script is responsible for setting up persistent read-write directories in a read-only rootfs.
This is done using overlay-filesystems that are mounted as read-write storage on top of the RootFS/targets.
The targets, filesystem-types and -flag can be configured via *bootparam_overlayXXX*.

See :ref:`implementations/operatingsystem/initramfs-framework/10-netfield_init:bootparam_overlayXXX` for more information.

.. graphviz::
   :align: center
   :caption: Flowchart: **overlayfs**

   digraph flowchart_overlayfs {
      graph [href="#" target="_parent"]
      node [shape=rect width=0 height=0 margin="0.01,0.01" fontsize=8];
      edge [fontsize=8];

      Start [shape=oval color=gold style=filled]
      Start -> a0

      a0 [label="bootparam_overlaytargets\ndefined?" shape=diamond]
      a0 -> a1 [label="yes"]
      a0 -> End [label="no"]

      a1 [label="bootparam_overlay\nreferences a block-device?" shape=diamond]  
      a1 -> a2a [label="yes"]
      a1 -> a2b [label="no"]

      a2a [label="mount block-device\nas rw-storage"]
      a2a -> a3

      a2b [label="mount tmpfs\nas rw-storage"]  
      a2b -> a3

      a3 [label="assign the first/next target to 't'" xlabel="targets=[bootparam_overlaytargets]"]
      a3 -> a4

      a4 [label="create rw-storage directory\nfor the target" style=filled]
      a4 -> a5

      a5 [label="mount rw-storage as target overlay" style=filled]
      a5 -> a6

      a6 [label="is 't' the last target?" shape=diamond]
      a6 -> End [label="yes"]
      a6 -> a3 [label="no"]

      End [shape=oval color=gold style=filled] 
   }
