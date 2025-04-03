import bb
from pathlib import Path
import sys
import shutil
import tempfile
from oeqa.runtime.case import OERuntimeTestCase

class BaseTest(OERuntimeTestCase):

    def test_journald_log(self):
        # tc: OETestContext = self.tc
        bb.verbnote("Entering test-case: %s" % (sys._getframe().f_code.co_name))
        
        # Reboot to free the journald log of all entries except the boot logs.
        status, output = self.target.run('reboot')
        self.target.wait_until_booted()
        
        files_folder = Path(__file__).absolute().parent.parent / 'files/journald-log-tests'
        with tempfile.NamedTemporaryFile() as archive:
            archive_path = shutil.make_archive(archive.name, format='tar', root_dir=files_folder)
            self.target.copyTo(archive_path, "/tmp/journald-log-tests.tar")

            cmd =  ("echo                                                   ;"
                    "echo Starting journald-log tests on device: $(date)    ;"
                    "echo === journald-log-test started \(uptime: $(cat /proc/uptime | cut -d. -f1)s\) === | systemd-cat -t journald-log-test -p warning  ;"

                    "echo Create a new test directory ...                   ;"
                    "rm -vrf /tmp/journald-log-tests/*                      ;"
                    "mkdir -p /tmp/journald-log-tests                       ;"
                    "cd /tmp/journald-log-tests                             ;"

                    "echo Extract the delivered TAR archive ...             ;"
                    "echo PWD: $(pwd)                                       ;"
                    "tar -vxf ../journald-log-tests.tar                     ;"

                    "echo Wait until 90 seconds of uptime is reached ...    ;"
                    "while [ $(cat /proc/uptime | cut -d. -f1) -lt 90 ]; do sleep 1; done;  "
                    "echo Uptime: $(cat /proc/uptime | cut -d. -f1)s        ;"

                    "echo Run the test ...                                  ;"
                    "echo PWD: $(pwd)                                       ;"
                    "python3 test.py " + self.td.get('MACHINE') + ".log     ;"
                    "JOURNALD_LOG_TEST_RESULT=$?                            ;"

                    "echo Clean-Up ...                                      ;"
                    "cd ..                                                  ;"
                    "rm -vrf /tmp/journald-log-tests*                       ;"

                    "echo Exiting journald-log tests \(error_count=$JOURNALD_LOG_TEST_RESULT\) ...  ;"
                    "exit $JOURNALD_LOG_TEST_RESULT                         ;")

            rt, output = self.target.run(cmd)
            #bb.verbnote("output: %s" % output)
            self.assertEqual(rt, 0, output)

        bb.verbnote("Exiting test-case: %s" % (sys._getframe().f_code.co_name))
