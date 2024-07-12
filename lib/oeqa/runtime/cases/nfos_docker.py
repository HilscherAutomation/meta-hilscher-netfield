import bb
from pathlib import Path
import logging
import shutil
import tempfile
from oeqa.runtime.case import OERuntimeTestCase
from oeqa.core.target.ssh import OESSHTarget

# from oeqa.runtime.context import OETestContext


class BaseTest(OERuntimeTestCase):
    target: OESSHTarget

    def test_docker(self):
        # tc: OETestContext = self.tc
        files_folder = Path(__file__).absolute().parent.parent / "files"
        test_files = files_folder / "docker-tests-helpers"
        with tempfile.NamedTemporaryFile() as archive:
            archive_path = shutil.make_archive(archive.name, format='tar', root_dir=test_files)
            self.target.copyTo(archive_path, "/tmp/compose-tests.tar")
            cmd =  ("echo                                        ;"
                    "echo -n 'Starting docker test on device: '  ;"
                    "date                                        ;"
                    "echo  Clean and Setup Working Directory     ;"
                    "cd /tmp                                     ;" 
                    "rm -vrf compose-tests docker_test_result    ;"
                    "mkdir compose-tests                         ;"
                    "cd compose-tests                            ;"
                    "echo  Extract TAR                           ;"
                    "echo  PWD: $(pwd)                           ;"
                    "tar -vxf ../compose-tests.tar               ;"
                    "echo  -----------------------------------   ;"
                    "echo             RUN TESTS                  ;"
                    "echo  -----------------------------------   ;"
                    "echo  PWD: $(pwd)                           ;"
                    "tree                                        ;"
                    "echo 'TEST CMD: python3 -m unittest -v'     ;"
                    "python3 -m unittest -v                      ;"
                    "echo -n $? > /tmp/docker_test_result        ;"
                    "echo  Clean-Up                              ;"
                    "cd ..                                       ;"
                    "rm -vrf compose-tests compose-tests.tar     ;"
                    "exit $(cat docker_test_result)              ;")
            rt, output = self.target.run(cmd)
            bb.verbnote(output)
            self.assertEqual(rt, 0, output)
