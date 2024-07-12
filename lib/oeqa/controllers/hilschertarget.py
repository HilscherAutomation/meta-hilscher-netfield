import bb
import os, shutil
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

        self.swu_update_file = os.path.dirname(kwargs['rootfs'])+ "/" + os.path.basename(kwargs['rootfs']).split('.')[0] + ".update.swu"
        self.swu_recovery_file = os.path.dirname(kwargs['rootfs'])+ "/" + os.path.basename(kwargs['rootfs']).split('.')[0] + ".recovery.swu"

    ''' Wait until the target device has booted (if we have just power cycled it). '''
    def wait_until_booted(self, timeout=181):
        bb.verbnote("Waiting for SSH daemon on %s (%s)" % (self.target_ip, self.ip))

        time.sleep(30)

        magic_exit_code = 123
        cmd = "exit %d" % magic_exit_code

        end_time = time.time() + timeout
        bb.verbnote("Waiting for SSH daemon on %s (%s) - timeout in %d seconds" % (self.target_ip, self.ip, end_time - time.time()))
        while True:
            status, output = super(HilscherTarget, self).run(cmd, timeout=1) # Note: The underlying SSHCall expands this timeout to 10sec.
            if status == magic_exit_code:
                break
            if time.time() > end_time:
                bb.fatal("Waiting for %s (%s) timed out!" % (self.target_ip, self.ip))

            bb.verbnote("Waiting for SSH daemon on %s (%s) - timeout in %d seconds" % (self.target_ip, self.ip, end_time - time.time()))

        bb.verbnote("Waiting for SSH daemon on %s (%s) successfully done" % (self.target_ip, self.ip))

        return 0

    def swu_update(self):
        src = os.path.realpath(self.swu_update_file)
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

        return 0

    def swu_recovery(self):
        src = os.path.realpath(self.swu_recovery_file)
        dst = "/tmp/" + os.path.basename(src)

        ''' Create a new directory for DUT onboarding information. '''
        dev_dir = "dev_" + self.ip
        if os.path.isdir(dev_dir):
            shutil.rmtree(dev_dir)
        os.mkdir(dev_dir)

        ''' Backup DUT onboarding information. '''
        if self.copyFrom("/etc/aziot/onboard.json", dev_dir + "/onboard.json"):
            self.copyFrom("/etc/aziot/config.toml", dev_dir + "/config.toml")

        bb.verbnote("Deploying %s to %s (%s)" % (os.path.basename(src), self.target_ip, self.ip))

        ''' Upload new swu image file to target device. '''
        self.copyTo(src, dst)

        ''' Update target device. '''
        cmd = "swupdate-client " + dst
        status, output = super(HilscherTarget, self).run(cmd)
        if status:
             bb.fatal("Command '%s' returned non-zero exit status %d: %s" % (cmd, status, output))

        ''' Wait until the target device has rebooted after power cycle (timeout=301s). '''
        self.wait_until_booted(301)

        ''' Recover DUT onboarding information and start/enable the edge daemon. '''
        if os.path.isfile(dev_dir + "/onboard.json"):
            self.copyTo(dev_dir + "/onboard.json", "/etc/aziot/onboard.json")
            self.copyTo(dev_dir + "/config.toml", "/etc/aziot/config.toml")
            cmd = "systemctl enable aziot-edged && iotedge config apply"
            status, output = super(HilscherTarget, self).run(cmd)
            if status:
                bb.fatal("Command '%s' returned non-zero exit status %d: %s" % (cmd, status, output))

        return 0

    def start(self, **kwargs):
        self.swu_update()
        bb.verbnote("Starting tests on %s (%s)" % (self.target_ip, self.ip))
