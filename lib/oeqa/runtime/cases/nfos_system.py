from oeqa.runtime.case import OERuntimeTestCase
from oeqa.core.decorator.depends import OETestDepends
from oeqa.runtime.decorator.package import OEHasPackage

import re

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
