==============================
Customization via device label
==============================

.. :Author: Michael Trensch <mtrensch@hilscher.com>

To allow simple customizations without the need to provide special images,
it is possible to influence the initial setup (e.g. after recovery). This
is done by providing a customized version of the device label.

| The format of the device-label is defined in a JSON schema. See :download:`device-label.json.schema <device-data/device-data.schema.json>`
| There is also a sample device label available See :download:`device-label.json <device-data/device-data.json>`

.. Note::

    The device label must be signed using the device key and is bound to the device using
    the MAC address of eth0, to prevent tampering.

All settings from device label will only be applied to the system on first boot after a recovery.
Changes in the device label will not result in re-applying these settings.

.. Note::

    To re-apply the settings, either do a factory reset or delete the file "/etc/.branding_done" and reboot

Available settings
==================

As the device label is limited in size and content it can only influence some basic settings

 * DeviceManager default ports
 * DeviceManager plugins (allow or block list)
 * SSH Service settings (port and enable/disable)
 * User docker settings (enabled/disable)
 * NTP settings (synchronized, timezone and servers)
 * Automatic onboarding (zeroTouch onboarding)
 * Pre-Configuration of Ethernet Interface
 * netFIELD Cloud onboarding options (modes, endpoints, protocol)
 * Keylock / Remote-Access settings (on/off)

 * Customize user accounts (groups, shell, password).

   .. Note::

       Password is not readable, as hashed input from openssl must be given. See the following example:
       .. code-block::

           echo <password> | openssl passwd -6 -stdin

Examples
========

Change default admin user settings
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To change the password to "Hilscher" of the default admin user a device label must contain the following object part:

.. code-block:: json

    {
        "oem_data": {
            "branding": {
                "users": [{
                    "name": "admin",
                    "mode": "change",
                    "password": "$6$w2Ji5Hz2OiF7veQC$OgWiU8r57eieHk5428X42W1fI2IkHxxfSfQccH7OLOz1wyvOU351uglyQPurzp0v0ar8SOh.7RCiznGImvIUM/",
                    "forcePasswordChange": true
                }]
            }
        }
    }

Password was generated as follows

.. code-block::

    $ echo Hilscher | openssl passwd -6 -in -
    $6$w2Ji5Hz2OiF7veQC$OgWiU8r57eieHk5428X42W1fI2IkHxxfSfQccH7OLOz1wyvOU351uglyQPurzp0v0ar8SOh.7RCiznGImvIUM/

.. Note::

    As the password contains a salt it will change every time executing this command

Hide device manager plugins
^^^^^^^^^^^^^^^^^^^^^^^^^^^

To hide Onboarding and Terminal plugin the following device label object can be used

.. code-block:: json

    {
        "oem_data": {
            "branding": {
                "deviceManager": {
                    "disabledPlugins": ["onboard", "terminal"]
                }
            }
        }
    }

Zero-Touch Onboarding
^^^^^^^^^^^^^^^^^^^^^

For zero-touch onboarding the device must be generated in the cloud and following parameters must be inserted into the device label:

 * registration id
 * scope id
 * symmetric key
 * global endpoint (optional)

The following device label object can be user

.. code-block:: json

    {
        "oem_data": {
            "iotedge": {
                "method": "symmetric_key",
                "registration_id": "<registration id>",
                "scope_id": "<scope id>",
                "symmetric_key": "<symmetric key>"
            }
        }
    }

Change default network setup
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In case a new network setup is requested you can setup each interface individually.

The following example sets up eth0 to be the main interface (default metric being smaller than eth1) and eth1 to be a local machine network.

.. code-block:: json

    {
        "oem_data": {
            "branding": {
                "interfaces": [
                    {
                        "name": "eth0",
                        "mode": "auto",
                        "metric": 100,
                    }, {
                        "name": "eth1",
                        "mode": "manual",
                        "address": "192.168.200.100/24",
                        "dns": ["192.168.200.1", "1.1.1.1"],
                        "gateway": "192.168.200.1",
                        "metric": 101,
                    }
                ]
            }
        }
    }

Use custom DNS settings for docker
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When using docker it is preferred to have static DNS entries, as those provided via DHCP may
not be used inside docker, depending on link state during docker startup. A custom device-label
allows to preset the default docker DNS servers

The following example sets up docker to use Cloudflare and Google DNS.

.. code-block:: json

    {
        "oem_data": {
            "branding": {
                "services": {
                    "docker": {
                        "dns": ["1.1.1.1", "8.8.8.8"]
                    }
                }
            }
        }
    }

