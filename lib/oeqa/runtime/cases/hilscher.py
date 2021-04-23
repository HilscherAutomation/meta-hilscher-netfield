from oeqa.runtime.case import OERuntimeTestCase
from oeqa.core.decorator.depends import OETestDepends
from oeqa.runtime.decorator.package import OEHasPackage

class HilscherBase(OERuntimeTestCase):

    def test_required_files(self):
        files = ('/firmware.image_name', '/firmware.manifest', '/firmware.version',)
        files += ('/etc/hwrevision',)
        for f in files:
            cmd = 'test -r %s' % f
            status, output = self.target.run(cmd)
            self.assertEqual(status, 0, '%s failed!\n' % cmd)

    @OETestDepends(['hilscher.HilscherBase.test_required_files'])
    def test_firmware_image_name(self):
        cmd = 'cat /firmware.image_name'
        status, output = self.target.run(cmd)
        image_name = self.td.get('IMAGE_NAME')
        self.assertEqual(output, image_name, 'Unexpected firmware image %s found!\n' % output)
