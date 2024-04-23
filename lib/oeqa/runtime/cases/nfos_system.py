from oeqa.runtime.case import OERuntimeTestCase
from oeqa.core.decorator.depends import OETestDepends
from oeqa.runtime.decorator.package import OEHasPackage

import re
import time

class BaseTest(OERuntimeTestCase):

    ''' ======================================== '''
    def test_backup_mount(self):
        cmd = 'mount | grep backup'
        status, output = self.target.run(cmd)

        self.assertEqual(output, "/dev/mapper/data-backup on /mnt/backup type ext4 (rw,relatime)", 'Invalid or missing backup partition mount!\n')

    ''' ======================================== '''
    def convert_to_bytes(self, size_str):
        ''' Converts torrent sizes to a common count in bytes. '''

        temp = re.compile("([0-9]+)([a-zA-Z]+)")
        size_data = temp.match(size_str).groups()

        multipliers_list = ['B', 'KiB', 'MiB', 'GiB'], ['B', 'K', 'M', 'G']

        size_magnitude = int(size_data[0])
        for multipliers in multipliers_list:
            if size_data[1] in multipliers:
                multiplier_exp = multipliers.index(size_data[1])
        size_multiplier = 1024 ** multiplier_exp if multiplier_exp > 0 else 1

        return size_magnitude * size_multiplier

    def test_partitioning(self):
        boot_rescue_system_lvm = (
            ['boot', self.td.get('IMAGE_PART_BOOT_SIZE')],
            ['rescue', self.td.get('IMAGE_PART_RESCUE_SIZE')],
            ['system', self.td.get('IMAGE_PART_SYSTEM_SIZE')],
            ['lvm', self.td.get('IMAGE_PART_DATA_SIZE')],
        )
        machine_partition_list = {
            'netfield-compact-x8m-rev1': boot_rescue_system_lvm,
            'niot-e-nfl90-q2n16-n-rev1': boot_rescue_system_lvm,
            'netfield-iolink-edge-gw-rev1': boot_rescue_system_lvm,
            'netfield-iolink-edge-gw-rev2': boot_rescue_system_lvm,
            'niot-e-tpi51-en-re': boot_rescue_system_lvm,
            'niot-e-tijcx-gb': boot_rescue_system_lvm,
            'netfield-unity': boot_rescue_system_lvm,
        }
        partition_list = machine_partition_list.get(self.td.get('MACHINE'))
        self.assertIsNotNone(partition_list, 'Invalid or missing machine specific partition_list!')

        errors = 0
        for a in partition_list:
            if a[0] != "lvm":
                cmd = 'fdisk -l $(blkid -L %s) | head -n1 | cut -d" " -f5 | grep ^%s$' % (a[0], self.convert_to_bytes(a[1]))
                status, output = self.target.run(cmd)
                if status != 0:
                    errors += 1
                    bb.error(output)
            else:
                ''' TODO: Implementing a LVM validation (PV and LV). '''

        self.assertEqual(errors, 0, 'Invalid or missing partitions!\n')

    def test_arp_support(self):
        cmd = 'arp'
        status, output = self.target.run(cmd)
        self.assertEqual(status, 0, 'Error running arp command!\n')

    def test_backup(self):
        TEST_FILE='/home/admin/test_file'
        BACKUP_FILE='test.fsa'

        self.target.run('rm -f ' + TEST_FILE)

        # Create backup
        cmd = "fsa_backup -p '$(pwd) $(date)' -l 'This is a comment with spaces' " + BACKUP_FILE
        status, output = self.target.run(cmd)
        self.assertEqual(status, 0, 'Error executing backup (%s)!\n' % output)

        # Write temporary file that should vanish after restore
        self.target.run('touch ' + TEST_FILE)

        # Query backup info
        cmd = "fsa_info -p '$(pwd) $(date)' " + BACKUP_FILE
        status, output = self.target.run(cmd)
        self.assertEqual(status, 0, 'Error querying backup info (%s)!\n' % output)
        self.assertIn('comment=This is a comment with spaces', output, 'Wrong comment in output')

        # Perform restore
        cmd = "fsa_restore -p '$(pwd) $(date)' " + BACKUP_FILE
        status, output = self.target.run(cmd)
        self.assertIn('Rebooting in 5 seconds to restore backup', output, 'Error executing restore (%s)!' % output)

        time.sleep(15)
        self.target.wait_until_booted()

        # Check if testfile has vanished
        status, output = self.target.run('cat ' + TEST_FILE)
        self.assertNotEqual(status, 0, 'Restore was not executed, testfile still existing after restore!\n')

        # Delete backup file
        self.target.run('rm -f /mnt/backup/' + BACKUP_FILE)

    def test_zram(self):
        cmd = 'zramctl -o NAME,DISKSIZE'
        status, output = self.target.run(cmd)
        self.assertEqual(status, 0, 'Error querying zram (%s)' % output)
        self.assertIn('/dev/zram0', output, 'Unable to find required zram device (%s)' % output)

        cmd = 'swapon'
        status, output = self.target.run(cmd)
        self.assertEqual(status, 0, 'Error querying swap (%s)' % output)
        self.assertIn('/dev/zram0', output, 'Unexpected swap configuration (%s)' % output)

    def test_firewall(self):

        def firewall_reset_zone(interface):
            # Reset firewall zone
            cmd = 'nmcli c mod %s connection.zone ""' % interface
            status, output = self.target.run(cmd)
            self.assertEqual(status, 0, 'Error resetting firewall zone on %s (%s)' % (interface, output))

            status, output = self.target.run('firewall-cmd --reload')
            self.assertEqual(status, 0, 'Error reloading firewall (%s)' % output)

        def firewall_check_zone(interface, zone):
            # Set firewall zone via firewalld
            cmd = 'firewall-cmd --add-interface=%s --permanent --zone=%s' % (interface, zone)
            status, output = self.target.run(cmd)
            self.assertEqual(status, 0, 'Error setting firewall zone to %s on %s (%s)' % (zone, interface, output))
            self.assertIn('The interface is under control of NetworkManager, setting zone to', output, 'Unexpected result (%s)' % output)

            status, output = self.target.run('firewall-cmd --runtime-to-permanent')
            self.assertEqual(status, 0, 'Error permanently saving firewall configuration (%s)' % output)

            # Check if settings are available in NetworkManager
            cmd = 'nmcli c show %s | grep connection.zone | tr -s " " | cut -d " " -f2' % interface
            status, output = self.target.run(cmd)
            self.assertEqual(status, 0, 'Error querying zone for interface %s (%s)' % (interface, output))
            self.assertIn(zone, output, 'Unexpected zone on interface %s (%s)' % (interface, output))

            # Check if settings are available from firewall-cmd
            status, output = self.target.run('firewall-cmd --list-interface --zone=%s' % zone)
            self.assertEqual(status, 0, 'Error querying interfaces for zone (%s)' % output)
            self.assertIn(interface, output, 'Interface %s not found in zone %s on firewalld (%s)' % (interface, zone, output))

            # Check if settings are available via dbus
            cmd = ('dbus-send --system --dest=org.fedoraproject.FirewallD1 '
                   '--print-reply --type=method_call '
                   '/org/fedoraproject/FirewallD1 '
                   'org.fedoraproject.FirewallD1.zone.getZoneOfInterface '
                   'string:"%s"' % interface)
            status, output = self.target.run(cmd)
            self.assertEqual(status, 0, 'Error querying interfaces from FirewallD via dbus (%s)' % output)
            self.assertIn('string "%s"' % zone, output, 'Wrong zone queried via dbus from interface %s (%s)' % (interface, output))

        for interface in ["eth0", "eth1"]:
            # Check if interface is available (some devices only have a single ethernet interface
            status, output = self.target.run('test -e /sys/class/net/'+interface)
            if status != 0:
                # Skip unavailable interface
                bb.warn("Skipping unavailable interface %s" % interface)
                continue

            # Reset firewall zone
            firewall_reset_zone(interface)

            # Check all trusted zones (otherwise we may lockout ourself
            for zone in ["trusted", "nat_trusted"]:
                firewall_check_zone(interface, zone)

            # Reset firewall zone
            firewall_reset_zone(interface)

    def test_hostname_change(self):
        status, output = self.target.run('hostname')
        self.assertEqual(status, 0, 'Error querying old hostname (%s)' % output)
        old_hostname = output

        def set_and_check_hostname(new_hostname):
            cmd = 'hostnamectl set-hostname %s' % new_hostname
            status, output = self.target.run(cmd)
            self.assertEqual(status, 0, 'Error setting new host name (%s)' % output)

            # Give dispatcher some time
            time.sleep(0.5)

            cmd = 'cat /etc/hosts'
            status, output = self.target.run(cmd)
            self.assertEqual(status, 0, 'Error reading hosts file (%s)' % output)
            self.assertIn('127.0.1.1 %s' % new_hostname, output, 'Unexpected hostname in /etc/hosts (%s)' % (output))


        for hostname in ['new-hostname', 'changed-hostname']:
            set_and_check_hostname(hostname);

        set_and_check_hostname(old_hostname);
