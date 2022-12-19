.. _special_usergroups_and_their_permissions:

========================================
Special usergroups and their permissions
========================================

.. :Author: Michael Trensch <mtrensch@hilscher.com>

Introduction
^^^^^^^^^^^^

netFIELDOS basically uses a default permission system oriented on https://wiki.debian.org/SystemGroups.
Not all groups are available/supported (e.g. wheel).

There are some special user groups for system admistration purposes which are describes in the following chapters


Additional administrator groups
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

+-----------------+-----------------------------------------------------------------------+
| System group    | Granted Permissions                                                   |
+=================+=======================================================================+
| netadmin        | * read/write files in /etc/gateway/                                   |
|                 | * read system logs (/run/log/journal and /var/log/journal)            |
|                 | * Execute helper scripts via sudo (provided in /usr/libexec/cockpit/) |
|                 | * start/stop/restart/enable/disable cifxtun service                   |
|                 | * restart dnsmasq service                                             |
|                 | * start/stop/restart/enable/disable firewalld service                 |
|                 | * Change firewalld policies                                           |
|                 | * Change modem settings (ModemManager) required for e.g. LTE          |
|                 | * Change all network manager settings                                 |
|                 | * Read/write /etc/nginx/nginx.conf (e.g. setup port via cockpit)      |
|                 | * Read/write /etc/default/iotedge/bridge (default bridge config)      |
|                 | * Read/write /etc/docker/iotedge.json and /etc/docker/daemon.json     |
|                 | * Read/write /etc/dnsmasq.d/*                                         |
+-----------------+-----------------------------------------------------------------------+
| timeadmin       | * read/write files in /etc/systemd/timesyncd.conf.d/                  |
|                 | * Configure timesync via timedatectl                                  |
+-----------------+-----------------------------------------------------------------------+
| docker-readonly | Read/Query all docker services                                        |
+-----------------+-----------------------------------------------------------------------+
