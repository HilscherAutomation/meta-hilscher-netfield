.. _initramfs_device_data:

======================================================================
Exporting device specific data to the runtime RootFS (**device_data**)
======================================================================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Recipe
   *meta-hilscher-netfield/recipes-core/initrdscripts/initramfs-netfield.bb*

Package
   *initramfs-netfield-device-data*

Script
   *device_data*

----

This script is used for the secure runtime provisioning of device data (device-label) such as *product_name*, *serial_number* and so on.
A signed file named *device_data* is verified against the owner certificate in */proc/sys/srm/owner-cert* and,
if successful, loaded into the dedicated kernel module *device-data*.
This module accepts data in JSON format and exposes these via file nodes, named to there JSON key names, in */sys/device_data*. 
Additionally, the *device-data* kernel module has a locking mechanism to protect all data against manipulations!


Requirements
   - *pub-key-loader* kernel driver
   - *device-data* kernel driver
   - *efivarfs* kernel driver
   - *openssl*

.. graphviz::
   :align: center
   :caption: Flowchart: **device_data**
   
   digraph flowchart_device_data  {
      graph [href="#" target="_parent"]
      node [shape=rect width=0 height=0 margin="0.01,0.01" fontsize=8];
      edge [fontsize=8];
   
      Start [shape=oval, color=gold, style=filled]
      Start -> a3

      a3 [label="nvd/device_data file\nexists on\nbackup partition?", shape=diamond]
      a3 -> a4 [label="yes"]
      a3 -> b0 [label="no"]

      a4 [label="verify device_data\nagainst local MAC address\nand owner pub-key" shape=diamond]
      a4 -> a5 [label="ok"]
      a4 -> c0 [label="failed", color=red, fontcolor=red]

      a5 [label="export device_data\nvia /sys/device_data/export", style="filled"]
      a5 -> a6

      c0 [label="export fake device_data\nvia /sys/device_data/export", style="filled"]
      c0 -> a6

      a6 [label="export signature of device_data\nvia /sys/device_data/export", style="filled"]
      a6 -> a7

      a7 [label="export pub-key\nvia /sys/device_data/export", style="filled"]
      a7 -> a8

      a8 [label="lock device_data driver\nvia /sys/device_data/lock", style="filled"]
      a8 -> End

      b0 [label="try to get device_data\nfrom efivar (Intel)"]
      b0 -> b1

      b1 [label="device_data\navailable?", shape=diamond]
      b1 -> b2 [label="yes"]
      b1 -> a4 [label="no"]
      
      b2 [label="export device_data\n to nvd/device_data file"]
      b2 -> a4

      End [shape=oval, color=gold, style=filled]
   }
