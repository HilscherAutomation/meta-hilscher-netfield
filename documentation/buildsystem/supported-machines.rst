==================
Supported Machines
==================

.. :Author: Frank Meisenbach <fmeisenbach@hilscher.com>

Intel
=====

.. csv-table::
   :widths: 10, 30
   :stub-columns: 1

   :term:`TEMPLATECONF`, "
   ../meta-hilscher-netfield-intel/conf/samples
   "

.. csv-table::
   :header: :term:`MACHINE`, :term:`IMAGE`
   :widths: 10, 30

   "
   | niot-e-tijcx-gb
   | niot-e-vm-en
   | generic-x64
   ", "
   | netfield-image
   "

   
Raspberry-PI
============

.. csv-table::
   :widths: 10, 30
   :stub-columns: 1

   :term:`TEMPLATECONF`, "
   ../meta-hilscher-netfield-raspberrypi/conf/samples
   "

.. csv-table::
   :header: :term:`MACHINE`, :term:`IMAGE`
   :widths: 10, 30

   "
   | niot-e-tpi51-en-re
   ", "
   | netfield-image
   "


NXP / imx8
==========

.. csv-table::
   :widths: 10, 30
   :stub-columns: 1

   :term:`TEMPLATECONF`, "
   ../meta-hilscher-netfield-imx8/conf/samples
   "

.. csv-table::
   :header: :term:`MACHINE`, :term:`IMAGE`
   :widths: 10, 30

   "
   | netfield-compact-x8m-rev1
   | niot-e-nfl90-q2n16-n-rev1
   ", "
   | netfield-image-oem
   | netfield-image-oem-all
   | └── hilscher-netfield-image-oem-netfield
   "
   "
   | netfield-iolink-edge-gw-rev2
   ", "
   | netfield-image-oem
   | netfield-image-oem-all
   | ├── hilscher-netfield-image-oem-netfield
   | └── hilscher-netfield-image-oem-sensoredge
   "
