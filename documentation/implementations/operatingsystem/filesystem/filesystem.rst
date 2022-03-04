==========
Filesystem
==========

.. :Author: Sebastian Döll <sdoell@hilscher.com>

Introduction
============

The filesystem layout and all its parameters like types and sizes is determined by the purpose of best mix of security and flexibiltiy.
The netFIELD OS is based on a read only root files system as squashfs file. This root files system is signed and will be checked every 
boot. In case of a verification failure the system will stop the boot process.

On top of the read only file system overlay directories can be specified which allow write access to be able to store user data or allow 
persistent configuration changes.

The update and backup process requires additional partitions.

In case the system becomes inaccessible by an user application or any other reason the system provides a separate partition which contains a rescue Image 
which allows to boot anyway and to try to fix the error or safe the data.


TBD ...

Filesystem layout and configuration
===================================

The file system layout is mainly a read-only root filesystem,
delivered as signed squashfs file, and overlays on specific directories.

This prevents write access to critical location and exchanging system
files directly.

Two different partition layouts exist to support storing the previous
version of the OS in case an update fails.
The previous version is selectable via boot menu

Two partition schemes exists
 * One single system partition (default)
 * Two separate system partitions

**NOTE:** Both schemes can either use msdos or gpt partition table format
**NOTE2:** Filesystem will be resized and adjusted during first boot
of a device and **MUST NOT** be interrupted.

Partition layout: Single system partition
=========================================

This scheme is set if WKS_FILE is set to either
"hilscher-gpt-boot-rescue-system-lvm.wks.in" or
"hilscher-msdos-boot-rescue-system-lvm.wks.in"

The layout is as follows:

+-----------+--------------+---------+--------------------------------+
| Partition | Typical size | FS Type | Content                        |
+===========+==============+=========+================================+
| boot      | 64M          | VFAT    | Boot code                      |
+-----------+--------------+---------+--------------------------------+
| rescue    | 128M         | EXT4    | Rescue image                   |
+-----------+--------------+---------+--------------------------------+
| system    | 1G           | EXT4    | System files (kernel + rootfs) |
+-----------+--------------+---------+--------------------------------+
| data      | Rest of disk | LVM     | Backup and overlay storage     |
+-----------+--------------+---------+--------------------------------+

The logical volumes on the LVM data partition are configured as follows

+-----------+--------------+---------+--------------------------------+
| Volume    | Typical size | FS Type | Content                        |
+===========+==============+=========+================================+
| backup    | 35 %         | EXT4    | device label (copy) / Backups  |
+-----------+--------------+---------+--------------------------------+
| data      | 60 %         | EXT4    | Overlay data / container store |
+-----------+--------------+---------+--------------------------------+
| snapshot  |  5 %         | none    | Used during backup only        |
+-----------+--------------+---------+--------------------------------+

**NOTE:** Sizes must be explicitly set by machine and may differ from
machine to machine. See the *Setup partition sizes*

Partition layout: Dual system partition
=======================================

This scheme is set if WKS_FILE is set to either
"hilscher-gpt-boot-system-system-lvm.wks.in" or
"hilscher-msdos-boot-system-system-lvm.wks.in"

The layout is as follows:

+-----------+--------------+---------+--------------------------------+
| Partition | Typical size | FS Type | Content                        |
+===========+==============+=========+================================+
| boot      | 64M          | VFAT    | Boot code                      |
+-----------+--------------+---------+--------------------------------+
| system    | 512M         | EXT4    | System files (kernel + rootfs) |
+-----------+--------------+---------+--------------------------------+
| system    | 512M         | EXT4    | System files (kernel + rootfs) |
+-----------+--------------+---------+--------------------------------+
| data      | Rest of disk | LVM     | Backup and overlay storage     |
+-----------+--------------+---------+--------------------------------+

The logical volumes on the LVM data partition are configured as follows

+-----------+--------------+---------+--------------------------------+
| Volume    | Typical size | FS Type | Content                        |
+===========+==============+=========+================================+
| backup    | 35 %         | EXT4    | device label (copy) / Backups  |
+-----------+--------------+---------+--------------------------------+
| data      | 60 %         | EXT4    | Overlay data / container store |
+-----------+--------------+---------+--------------------------------+
| snapshot  |  5 %         | none    | Used during backup only        |
+-----------+--------------+---------+--------------------------------+

**NOTE:** Sizes must be explicitly set by machine and may differ from
machine to machine. See the *Setup partition sizes*

Setup partition sizes
=====================

The partition sizes and scheme must be set by machine.

Environment variables for file system configuration

+-----------------------------+---------------------------+------------+
| Name                        | Description               | Examples   |
+=============================+===========================+============+
| IMAGE_PART_BOOT_SIZE        | Size of boot partition    | 64M        |
+-----------------------------+---------------------------+------------+
| IMAGE_PART_RESCUE_SIZE      | Size of rescue partition  | 128M       |
+-----------------------------+---------------------------+------------+
| IMAGE_PART_SYSTEM_SIZE      | Size of system partition  | 1G         |
+-----------------------------+---------------------------+------------+
| IMAGE_PART_DATA_SIZE        | Size of data partition    | max        |
+-----------------------------+---------------------------+------------+
| PART_DATA_LV_DATA_SIZE      | Size of data volume       | 60%        |
+-----------------------------+---------------------------+------------+
| PART_DATA_LV_BACKUP_SIZE    | Size of backup volume     | 35% / 768M |
+-----------------------------+---------------------------+------------+
| PART_DATA_LV_SNAPSHOT_SIZE  | Size of snapshot volume   | 5%         |
+-----------------------------+---------------------------+------------+

Writable directories / Overlays
===============================

As the root filesystem is read-only some folders use overlays,
which are backup by logical volume named *data*.

Per default the following folders are automatically converted to overlays:
 * /etc
 * /home
 * /opt
 * /var/lib
 * /var/log
 * /usr/local
 * /var/secrets

This is configured via the variable NETIOT_OVERLAY_DIRS.

You can place an overlay on top of all folders by setting
NETIOT_ROOT_OVERLAY to "1"

Mount points exposed and used by the system
===========================================

+----------------+-------------------------+--------------------------------+
| Mount point    | Target                  | Used by                        |
+================+=========================+================================+
| /mnt/backup    | /dev/mapper/data-backup | Device label or Backup/Restore |
+----------------+-------------------------+--------------------------------+
| /run/overlay   | /dev/mapper/data-data   | Overlay/user data              |
+----------------+-------------------------+--------------------------------+
