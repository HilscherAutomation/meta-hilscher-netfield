from oeqa.runtime.case import OERuntimeTestCase
from oeqa.core.decorator.depends import OETestDepends
from oeqa.runtime.decorator.package import OEHasPackage

class Base(OERuntimeTestCase):

    ''' ======================================== '''
    dev_list_niot_e_nfl90_q2n16_n_revX = (
        'gpio@30200000', 'gpio@30210000', 'gpio@30220000', 'gpio@30230000', 'gpio@30240000',
        'serial@30860000', 'serial@30880000', 'serial@30890000',
        'i2c@30a20000', 'i2c@30a30000',
        'spi@30820000', 'spi@30830000', 'spi@30840000',
        'usb@32e40000', 'usb@32e50000',
        'ethernet@30be0000',
        'pinctrl@30330000',
    )
    dev_list_netfield_iolink_edge_gw_revX = (
        'gpio@30200000', 'gpio@30210000', 'gpio@30220000', 'gpio@30230000', 'gpio@30240000',
        'serial@30880000',
        'i2c@30a20000', 'i2c@30a30000', 'i2c@30a50000',
        'spi@30840000',
        'ethernet@30be0000',
        'pinctrl@30330000',
    )
    dev_list_niot_e_tpi51_en_re = (
        '3f007000.dma', 
        '3f200000.gpio', 
        '3f201000.serial',
        '3f204000.spi', '3f215080.spi', '3f215000.aux',
        '3f804000.i2c',
    )
    dev_list_niot_e_tijcx_gb = (
    )

    machine_dev_list = {
        'niot-e-nfl90-q2n16-n-rev1': dev_list_niot_e_nfl90_q2n16_n_revX,
        'netfield-iolink-edge-gw-rev1': dev_list_netfield_iolink_edge_gw_revX,
        'netfield-iolink-edge-gw-rev2': dev_list_netfield_iolink_edge_gw_revX,
        'niot-e-tpi51-en-re': dev_list_niot_e_tpi51_en_re,
        'niot-e-tijcx-gb': dev_list_niot_e_tijcx_gb,
    }

    def test_proc_iomem_entries(self):
        dev_list = self.machine_dev_list.get(self.td.get('MACHINE'))
        self.assertIsNotNone(dev_list, 'Invalid or missing machine specific dev_list!')

        errors = 0
        for a in dev_list:
            cmd = 'cat /proc/iomem | grep %s' % a
            status, output = self.target.run(cmd)
            if status != 0:
                errors += 1
                bb.error("%s: No match" % cmd)

        self.assertEqual(errors, 0, 'Invalid or missing device(s): test_proc_iomem_entries failed!\n')

    ''' ======================================== '''
    led_list_niot_e_nfl90_q2n16_n_revX = (
        'act_green', 'act_red', 'apl_green', 'apl_red',
        'bt_blue', 'bt_red', 'led1_green', 'led1_red',
        'sys_rdy_yellow', 'sys_run_green', 'sta_green',
    )
    led_list_netfield_iolink_edge_gw_rev1 = (
        'apl_green', 'apl_red', 'cloud_green', 'cloud_red', 'edge_green', 'edge_yellow',
    )
    led_list_netfield_iolink_edge_gw_rev2 = (
        'wlan_blue', 'cloud_green', 'cloud_red', 'edge_green', 'edge_yellow',
    )
    led_list_niot_e_tpi51_en_re = (
        'led0', 'led1', 'user0:orange:user', 'user1:orange:user',
    )
    led_list_niot_e_tijcx_gb = (
        'pg0:orange:user', 'pg1:green:user', 'pg2:orange:user', 'pg3:orange:user', 'pg4:orange:user',
    )

    machine_led_list = {
        'niot-e-nfl90-q2n16-n-rev1': led_list_niot_e_nfl90_q2n16_n_revX,
        'netfield-iolink-edge-gw-rev1': led_list_netfield_iolink_edge_gw_rev1,
        'netfield-iolink-edge-gw-rev2': led_list_netfield_iolink_edge_gw_rev2,
        'niot-e-tpi51-en-re': led_list_niot_e_tpi51_en_re,
        'niot-e-tijcx-gb': led_list_niot_e_tijcx_gb,
    }

    def test_sys_class_leds_files(self):
        led_list = self.machine_led_list.get(self.td.get('MACHINE'))
        self.assertIsNotNone(led_list, 'Invalid or missing machine specific led_list!')

        errors = 0
        for a in led_list:
            cmd = 'ls /sys/class/leds/%s' % a
            status, output = self.target.run(cmd)
            if status != 0:
                errors += 1
                bb.error(output)

        self.assertEqual(errors, 0, 'Invalid or missing device(s): test_sys_class_leds_files failed!\n')

    ''' ======================================== '''
    gpio_list_niot_e_nfl90_q2n16_n_revX = (
        'gpiochip0', 'gpiochip32', 'gpiochip64', 'gpiochip96', 'gpiochip128',
        'gpio1', 'gpio3', 'gpio5', 'gpio6', 'gpio8', 'gpio11', 'gpio71', 'gpio73', 'gpio116', 'gpio147', 'gpio149',
    )
    gpio_list_netfield_iolink_edge_gw_revX = (
        'gpiochip0', 'gpiochip32', 'gpiochip64', 'gpiochip96', 'gpiochip128',
        'gpio6', 'gpio8', 'gpio11', 'gpio13',
    )
    gpio_list_niot_e_tpi51_en_re = (
        'gpiochip0', 'gpiochip100', 'gpiochip504',
        'gpio24', 
    )
    gpio_list_niot_e_tijcx_gb = (
        'gpiochip0', 'gpiochip330', 'gpiochip338', 'gpiochip382', 'gpiochip410',
        'gpio330', 'gpio331', 'gpio332', 'gpio333', 'gpio334', 'gpio335', 'gpio336', 'gpio337',
    )

    machine_gpio_list = {
        'niot-e-nfl90-q2n16-n-rev1': gpio_list_niot_e_nfl90_q2n16_n_revX,
        'netfield-iolink-edge-gw-rev1': gpio_list_netfield_iolink_edge_gw_revX,
        'netfield-iolink-edge-gw-rev2': gpio_list_netfield_iolink_edge_gw_revX,
        'niot-e-tpi51-en-re': gpio_list_niot_e_tpi51_en_re,
        'niot-e-tijcx-gb': gpio_list_niot_e_tijcx_gb,
    }

    def test_sys_class_gpio_files(self):
        gpio_list = self.machine_gpio_list.get(self.td.get('MACHINE'))
        self.assertIsNotNone(gpio_list, 'Invalid or missing machine specific gpio_list!')

        errors = 0
        for a in gpio_list:
            cmd = 'ls /sys/class/gpio/%s' % a
            status, output = self.target.run(cmd)
            if status != 0:
                errors += 1
                bb.error(output)

        self.assertEqual(errors, 0, 'Invalid or missing device(s): test_sys_class_gpio_files failed!\n')

