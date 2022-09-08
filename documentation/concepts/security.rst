================
Security Aspects
================

.. :Author: Michael Trensch <mtrensch@hilscher.com>

Introduction
============

To provide a maximum amount of the security to following points were taken into account
 * Signature checks wherever possible using a single device family key
 * Read-only / signed base file system with overlays to prevent modification
 * Kernel mandatory access control mechanism (apparmor)
 * System-call filtering (seccomp)
 * Local auditing system (with possibility to push logs to a different server)
 * Login Brute-force protection

Signature checks
================

The basic components are signature checked and booting is denied if a check
fails

See the following table for an overview

+-------------+-------------------------------+
| Component   | Signature check               |
+=============+===============================+
| Bootloader  | Checked by SoC (if available) |
+-------------+-------------------------------+
| Kernel      | Checked by bootloader         |
+-------------+-------------------------------+
| Rootfs      | Checked by kernel/initramfs   |
+-------------+-------------------------------+
| Updates     | Checked by update daemon      |
+-------------+-------------------------------+
| Overlays    | optional auditing, no check   |
+-------------+-------------------------------+

Brute-force protection for logins
=================================

SSH and DeviceManager logins are brute-force protected using a pam module (pam_abl) which is configured as follows:
 * Deny host (by IP) for 1 hour after 10 failed logins
 * Deny host (by IP) for 1 day after 30 failed logins

Auditing
========

An auditing service is running per default with the recommended following
default rules being enabled.

 * Basic config and iotedge key auditing (30-basic-configuration.rules)
 * NISPOM Chapter 8 rules (30-nispom.rules)
   See `NISPOMwithISLsMay2014.pdf <https://www.nispom.org/NISPOMwithISLsMay2014.pdf>`_
 * Operating System Protection Profile (OSPP)v4.2 (30-ospp-v42.rules)
   See `PP_OS_V4.2.1.pdf <https://www.commoncriteriaportal.org/files/ppfiles/PP_OS_V4.2.1.pdf>`_
 * pci-dss v3.1 auditing requirements (30-pci-dss-v31.rules and 10-base-config.rules)
   See `PCI DSS v3.1 Supporting Docs <https://www.pcisecuritystandards.org/minisite/en/pci-dss-supporting-docs-v31.php>`_
 * Audit all privileged applications, that have SUID bit set
   (31-privileged.rules)
 * Disable audit config runtime changes (99-finalize.rules)

Auditing rules will automatically be locked and cannot be changed at runtime
(see */etc/audit/rules.d/99-finalize.rules*).

Changing rules requires a reboot

**NOTE:** Auditing logs will only be written to local disk per default

Logging / Remote logging
========================

Per default all logging is done using journald and only stored locally.

An additional service can be activated to push logging messages
to a remote host.

See https://github.com/systemd/systemd-netlogd


System call filtering and kernel MAC
====================================

These features are mainly used by docker to isolate applications.
They were enhanced for local services, but may be altered by user.
