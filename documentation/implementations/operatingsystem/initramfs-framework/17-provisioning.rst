===============================================================================
Supporting configurations required by the production process (**provisioning**)
===============================================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-provisioning*

Script
   *provisioning*

----

This script intents to support manufacturing by establish a NFS connection and runs a production script which is used
to load e.g. product specific firmware images as well as device labels.
By this way, all product specific data can be saved accordingly on the device.

.. graphviz::
   :align: center
   :caption: Flowchart: **provisioning**

   digraph flowchart_provisioning {
      graph [href="#" target="_parent"]
      node [shape=rect width=0 height=0 margin="0.01,0.01" fontsize=8];
      edge [fontsize=8];
   
      Start [shape=oval color=gold style=filled]
      Start -> a3

      a3 [label="provisioning requested?" shape=diamond]  
      a3 -> End [label="no"]
      a3 -> a4 [label="yes"]
     
      a4 [label="mount bootparam_nfsroot\nas nfs-share"]
      a4 -> a5

      a5 [label="provision-tools/start\nfile exists\non nfs-share?" shape=diamond]
      a5 -> a7 [label="no"]
      a5 -> a6 [label="yes"] 

      a6 [label="execute\nprovision-tools/start" style="filled"]
      a6 -> a7

      a7 [label="umount nfs-share"]
      a7 -> End

      End [shape=oval color=gold style=filled] 
   }
