import bb
import os
import time
import pexpect
import subprocess

from oeqa.core.target.ssh import OESSHTarget

class HilscherTarget(OESSHTarget):
    def __init__(self, logger, target_ip, server_ip, **kwargs):
        '''super(HilscherTarget, self).__init__(logger, target_ip, server_ip, user='dutuser', **kwargs)'''
        super().__init__(logger, target_ip, server_ip, **kwargs)


        ''' This original variable value is only used for comments. '''
        self.target_ip = self.ip

        ''' To prevents early connection issues when booting, translate and save the real target IP address. '''
        self.ip = subprocess.getoutput("ping -c1 " + self.ip + " | head -n1 | cut -d\'(\' -f2 | cut -d\')\' -f1")

        self.swufile = os.path.dirname(kwargs['rootfs'])+ "/" + os.path.basename(kwargs['rootfs']).split('.')[0] + ".update.swu"

    ''' Wait until the target device has booted (if we have just power cycled it). '''
    def wait_until_booted(self):
        bb.verbnote("Waiting for %s (%s)" % (self.target_ip, self.ip))

        time.sleep(30)

        try:
            cmd = pexpect.spawn("ping " + self.ip, timeout=120)
            cmd.expect("64 bytes")
            cmd.close()
        except:
            bb.fatal("Waiting for %s (%s) timed out!" % (self.target_ip, self.ip))

    def deploy(self):
        src = os.path.realpath(self.swufile)
        dst = "/tmp/" + os.path.basename(src)

        bb.verbnote("Deploying %s to %s (%s)" % (os.path.basename(src), self.target_ip, self.ip))

        ''' Upload new swu image file to target device. '''
        self.copyTo(src, dst)

        ''' Update target device. '''
        cmd = "swupdate-client " + dst
        status, output = super(HilscherTarget, self).run(cmd)
        if status:
             bb.fatal("Command '%s' returned non-zero exit status %d: %s" % (cmd, status, output))

        ''' Wait until the target device has rebooted after power cycle. '''
        self.wait_until_booted()

    def start(self, **kwargs):
        self.deploy()
        bb.verbnote("Starting tests on %s (%s)" % (self.target_ip, self.ip))
