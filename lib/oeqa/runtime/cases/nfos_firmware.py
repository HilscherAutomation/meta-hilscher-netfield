from oeqa.runtime.case import OERuntimeTestCase
from oeqa.core.decorator.depends import OETestDepends
from oeqa.runtime.decorator.package import OEHasPackage

import re

class BaseTest(OERuntimeTestCase):

    ''' ======================================== '''
    def test_swupdate(self):
        from oeqa.controllers.hilschertarget import HilscherTarget

        # Get local IP-address
        cmd = "ip route get 1 | cut -d ' ' -f7"
        status, output = self.target.run(cmd)
        self.assertEqual(status, 0, '%s failed!\n' % cmd)
        self.target_ip = output

        self.image_name = ("%s/%s" % (self.td.get('DEPLOY_DIR_IMAGE'), self.td.get('IMAGE_LINK_NAME')))

        target = HilscherTarget(None, self.target_ip, None, rootfs = self.image_name)

        status = target.deploy()

        self.assertEqual(status, 0, 'Firmware update on %s failed!\n' % self.target_ip)

    ''' ======================================== '''
    @OETestDepends(['nfos_firmware.BaseTest.test_swupdate'])
    def test_required_files(self):
        files = ('/firmware.image_name', '/firmware.manifest', '/firmware.version',)
        files += ('/etc/hwrevision',)
        for f in files:
            cmd = 'test -r %s' % f
            status, output = self.target.run(cmd)
            self.assertEqual(status, 0, '%s failed!\n' % cmd)

    ''' ======================================== '''
    @OETestDepends(['nfos_firmware.BaseTest.test_required_files'])
    def test_firmware_image_name(self):
        cmd = 'cat /firmware.image_name'
        status, output = self.target.run(cmd)
        image_name = self.td.get('IMAGE_NAME')
        self.assertEqual(output, image_name, 'Unexpected firmware image %s found!\n' % output)
