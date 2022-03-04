=====================================================================
Processing factory default reset requests (**factory_default_reset**)
=====================================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-factory-default-reset*

Script
   *factory_default_reset*

----

The *factory_reset* script is responsible to perform a factory default reset.
If this is requested, all settings stored on the LVM data partition will be deleted by formatting.

.. graphviz::
   :align: center
   :caption: Flowchart: **factory_default_reset**

   digraph flowchart_factory_default_reset {
      graph [href="#" target="_parent"]
      node [shape=rect width=0 height=0 margin="0.01,0.01" fontsize=8];
      edge [fontsize=8];
   
      Start [shape=oval, color=gold, style=filled]
      Start -> a0

      a0 [label="assign the first/next label to 'l'", xlabel="label=[backup, system]"]
      a0 -> a1

      a1 [label="mount block device of 'l'"]
      a1 -> a2
      
      a2 [label="file '.factory_reset' exists?", shape=diamond]      
      a2 -> a3 [label="yes"]
      a2 -> b0 [label="no"]

      a3 [label="format LVM 'data' partition", style="filled"]
      a3 -> a4

      a4 [label="delete '.factory_reset'"]
      a4 -> a5

      a5 [label="umount block device"]
      a5 -> End

      b0 [label="umount block device"]
      b0 -> b1

      b1 [label="is 'l' the last label?", shape=diamond]
      b1 -> End [label="yes"]
      b1 -> a0 [label="no"]

      End [shape=oval, color=gold, style=filled]
   }
