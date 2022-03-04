=======================================================
Processing backup restore requests (**backup_restore**)
=======================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-backup-restore*

Script
   *backup_restore*

----

If restoring of an available backup is requested, all required steps are done by this script of initramfs-framework.
This is the place where modifications on the runtime environment as well as the data-/backup- partitions can done securely.
A request is signaled through a *.restore* file located on the backup partition.
All information is required for restoring the backup are available in this file.

.. note::
   Currently *data partition* and *full* backups are supported.

.. graphviz::
   :align: center
   :caption: Flowchart: **backup_restore**

   digraph flowchart_backup_restore {
      graph [href="#" target="_parent"]
      node [shape=rect width=0 height=0 margin="0.01,0.01" fontsize=8];
      edge [fontsize=8];

      Start [shape=oval color=gold style=filled]
      Start -> a0

      a0 [label="mount backup partition"]
      a0 -> a1

      a1 [label=".restore file exists?" shape=diamond]  
      a1 -> a2 [label="yes"]
      a1 -> a6 [label="no"]

      a2 [label="Retrieve informations\nabout the backup file" style=filled]
      a2 -> a3

      a3 [label="restore backup data" style=filled]
      a3 -> Reboot

      Reboot [shape=oval color=gold style=filled]

      a6 [label="umount backup partition"]
      a6 -> End

      End [shape=oval color=gold style=filled]
   }

