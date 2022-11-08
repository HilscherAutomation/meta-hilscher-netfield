from oeqa.runtime.case import OERuntimeTestCase
from oeqa.core.decorator.depends import OETestDepends
from oeqa.runtime.decorator.package import OEHasPackage

import bb, os, stat, grp, pwd

class BaseTest(OERuntimeTestCase):

    ''' ======================================== '''

    def fs_permission_test(self, ug_info, url, perms):
        perms = sorted(perms.upper())

        bb.note("fs_permission_test (ug_info=%s, url=%s, perms=%s):" % (ug_info, url, perms))

        # Retrieve wildcard URLs
        cmd = 'stat --format=%%n %s 2>/dev/null' % url
        status, urls = self.target.run(cmd)
        if status != 0:
            bb.warn ("  ... %s - No files or directories found - PASS" % (url))
            return 0

        # Iterate over all URLs
        for u in urls.split():
            # Retrieve UID, GID and the MODE of the given URL
            cmd = 'stat --format=%%u %s' % u
            status, fuid = self.target.run(cmd)
            cmd = 'stat --format=%%g %s' % u
            status, fgid = self.target.run(cmd)
            cmd = 'stat --format=%%f %s' % u
            status, fmode = self.target.run(cmd)
            fmode = int(fmode,16)
            cmd = 'stat --format=%%A %s' % u
            status, fmode_human = self.target.run(cmd)

            # If available, replace USER permissions by named ACL user rules
            acl_fmode = 0
            acl_user = False
            uids = ug_info.get('uid', '')
            for uid in uids.split():
                cmd = 'getfacl %s -np | grep ^user:%s:' % (u, uid)
                status, acl_rule = self.target.run(cmd)
                if status == 0:
                    acl_user = True
                    # Extract the correct 'effective' permissions
                    acl_rule = acl_rule.split()[-1].split(':')[-1]
                    if 'r' in acl_rule:
                        acl_fmode |= getattr(stat, 'S_I%s%s' % ('R', 'USR'))
                    if 'w' in acl_rule:
                        acl_fmode |= getattr(stat, 'S_I%s%s' % ('W', 'USR'))
                    if 'x' in acl_rule:
                        acl_fmode |= getattr(stat, 'S_I%s%s' % ('X', 'USR'))
            if acl_user:
                fmode = (fmode & ~0o700) | acl_fmode

            # If available, replace GROUP permissions by named ACL group rules
            acl_fmode = 0
            acl_group = False
            gids = ug_info.get('gids', '') or ug_info.get('gid', '')
            for gid in gids.split():
                cmd = 'getfacl %s -np | grep ^group:%s:' % (u, gid)
                status, acl_rule = self.target.run(cmd)
                if status == 0:
                    acl_group = True
                    # Extract the correct 'effective' permissions
                    acl_rule = acl_rule.split()[-1].split(':')[-1]
                    if 'r' in acl_rule:
                        acl_fmode |= getattr(stat, 'S_I%s%s' % ('R', 'GRP'))
                    if 'w' in acl_rule:
                        acl_fmode |= getattr(stat, 'S_I%s%s' % ('W', 'GRP'))
                    if 'x' in acl_rule:
                        acl_fmode |= getattr(stat, 'S_I%s%s' % ('X', 'GRP'))
            if acl_group:
                fmode = (fmode & ~0o70) | acl_fmode

            # Validate the desired USER, GROUP and OTHER permissions of the given URL
            if fuid == ug_info.get('uid', None) or acl_user:
                perm = 0
                for permtype in perms:
                    perm |= getattr(stat, 'S_I%s%s' % (permtype, 'USR'))
                if (fmode & 0o700) == perm:
                    bb.note ("  ... %s (uid=%s, gid=%s, perm=%s) - %sOWNER permissions matches - PASS" % (u, fuid, fgid, fmode_human, ['','ACL '][acl_user]))
                else:
                    bb.error ("  ... %s (uid=%s, gid=%s, perm=%s) - %sOWNER permissions mismatches - FAILED" % (u, fuid, fgid, fmode_human, ['','ACL '][acl_user]))
                    return 1
            elif fgid == ug_info.get('gid', None) or fgid in ug_info.get('gids', '') or acl_group:
                perm = 0
                for permtype in perms:
                    perm |= getattr(stat, 'S_I%s%s' % (permtype, 'GRP'))
                if (fmode & 0o070) == perm:
                    bb.note ("  ... %s (uid=%s, gid=%s, perm=%s) - %sGROUP permissions matches - PASS" % (u, fuid, fgid, fmode_human, ['','ACL '][acl_group]))
                else:
                    bb.error ("  ... %s (uid=%s, gid=%s, perm=%s) - %sGROUP permissions mismatches - FAILED" % (u, fuid, fgid, fmode_human, ['','ACL '][acl_group]))
                    return 1
            else:
                perm = 0
                for permtype in perms:
                    perm |= getattr(stat, 'S_I%s%s' % (permtype, 'OTH'))
                if (fmode & 0o007) == perm:
                    bb.note ("  ... %s (uid=%s, gid=%s, perm=%s) - OTHER permissions matches - PASS" % (u, fuid, fgid, fmode_human))
                else:
                    bb.error ("  ... %s (uid=%s, gid=%s, perm=%s) - OTHER permissions mismatches - FAILED" % (u, fuid, fgid, fmode_human))
                    return 1
        return 0

    ''' ======================================== '''

    def get_user_group_ids(self, name):
        cmd = 'getent passwd %s | cut -d":" -f3' % name
        status, uid = self.target.run(cmd)

        if uid:
            cmd = 'getent passwd %s | cut -d":" -f4' % name
            status, gid = self.target.run(cmd)
            cmd = 'id -G %s' % name
            status, gids = self.target.run(cmd)
            return {'user':name,'uid':uid, 'gid':gid, 'gids':gids}

        cmd = 'getent group %s | cut -d":" -f3' % name
        status, gid = self.target.run(cmd)
        if gid:
            return {'group':name, 'gid':gid}

        return None


    ''' ======================================== '''

    def test_netadmin_group_permissions(self):
        group = "netadmin"
        ug_info = self.get_user_group_ids(group)

        # Add a temporary user.
        user = "tmp_%s" % group
        cmd = "useradd %s -g %s" % (user, group)
        status, output = self.target.run(cmd)
        #self.assertEqual(status, 0, '\'%s\' failed\n' % cmd)

        errors = 0

        # ===========================
        # Test filesystem permissions
        # ===========================

        urls = {'/etc/gateway/':'RWX',
                '/etc/gateway/*':'RW',
                '/*/log/journal/':'RX',
                '/*/log/journal/*':'RX',
                '/*/log/journal/*/system.journal':'R',
                '/usr/libexec/cockpit/':'RX',
                '/etc/nginx/nginx.conf':'RW',
                '/etc/default/iotedge/bridge':'RW',
                '/etc/docker/iotedge.json':'RW',
                '/etc/docker/daemon.json':'RW',
                '/etc/dnsmasq.d/':'RWX',
                '/etc/dnsmasq.d/*':'RW'}

        for k in urls.keys():
            status = self.fs_permission_test(ug_info, k, urls[k])
            if status != 0:
                errors += 1

        self.assertEqual(errors, 0, 'Invalid filesystem permissions for %s!\n' % ug_info)

        # ========================
        # Test sudoers permissions
        # ========================

        cmd = "ls /usr/libexec/cockpit/*"
        status, urls = self.target.run(cmd)
        self.assertEqual(status, 0, "'%s' failed\n" % cmd)

        for u in urls.split():
            cmd = "sudo -u %s sudo -l | grep %s$ | grep '(ALL : ALL) NOPASSWD:'" % (user, u)
            status, output = self.target.run(cmd)
            if status != 0:
                bb.error ("sudoers_permission_test (ug_info=%s, url=%s) - FAILED" % (ug_info, u))
                errors += 1
            else:
                bb.note ("sudoers_permission_test (ug_info=%s, url=%s) - PASS" % (ug_info, u))

        self.assertEqual(errors, 0, 'Invalid sudoers permissions for %s!\n' % ug_info)

        # =======================
        # Test polkit permissions
        # =======================

        # Change all network manager settings
        cmd = "pkaction | grep org.freedesktop.NetworkManager | tr '\n' ',' | sed 's/,$//'"
        status, output = self.target.run(cmd)
        actions = "%s" % output
        # Change modem settings (ModemManager) required for e.g. LTE
        cmd = "pkaction | grep org.freedesktop.ModemManager* | tr '\n' ',' | sed 's/,$//'"
        status, output = self.target.run(cmd)
        actions += ",%s" % output
        # Change firewalld policies
        cmd = "pkaction | grep org.fedoraproject.FirewallD* | tr '\n' ',' | sed 's/,$//'"
        status, output = self.target.run(cmd)
        actions += ",%s" % output

        # restart dnsmasq service
        actions += ",org.freedesktop.systemd1.manage-units -d unit dnsmasq.service -d verb restart"
        # start/stop/restart/enable/disable cifxtun service
        actions += ",org.freedesktop.systemd1.manage-units -d unit cifxtun.service -d verb start"
        actions += ",org.freedesktop.systemd1.manage-units -d unit cifxtun.service -d verb stop"
        actions += ",org.freedesktop.systemd1.manage-units -d unit cifxtun.service -d verb restart"
        actions += ",org.freedesktop.systemd1.manage-units -d unit cifxtun.service -d verb enable"
        actions += ",org.freedesktop.systemd1.manage-units -d unit cifxtun.service -d verb disable"
        # start/stop/restart/enable/disable firewalld service
        actions += ",org.freedesktop.systemd1.manage-units -d unit firewalld.service -d verb start"
        actions += ",org.freedesktop.systemd1.manage-units -d unit firewalld.service -d verb stop"
        actions += ",org.freedesktop.systemd1.manage-units -d unit firewalld.service -d verb restart"
        actions += ",org.freedesktop.systemd1.manage-units -d unit firewalld.service -d verb enable"
        actions += ",org.freedesktop.systemd1.manage-units -d unit firewalld.service -d verb disable"

        # Create a user session to test polkit permissions in it.
        cmd = "su %s </dev/zero &>/dev/null &" % user
        status, output = self.target.run('%s' % cmd)
        self.assertEqual(status, 0, "'%s' failed\n" % cmd)

        for a in actions.split(','):
            cmd = "pkcheck -a %s -p $(pgrep -u %s)" % (a, user)
            status, output = self.target.run('%s' % cmd)
            if status != 0:
                bb.error ("polkit_permission_test (ug_info: %s, action_id: %s): %s - FAILED" % (ug_info, a, output))
                errors += 1
            else:
                bb.note ("polkit_permission_test (ug_info: %s, action_id: %s) - PASS" % (ug_info, a))

        # Cleanup/Remove the used user session.
        cmd = "kill -KILL $(pgrep -u %s)" % user
        status, output = self.target.run('%s' % cmd)
        self.assertEqual(status, 0, "'%s' failed\n" % cmd)



        # Remove the temporary user.
        cmd = "userdel -r %s" % user
        status, output = self.target.run(cmd)
        #self.assertEqual(status, 0, "'%s' failed\n" % cmd)

        self.assertEqual(errors, 0, "Invalid polkit permissions for %s!\n" % ug_info)

    ''' ======================================== '''

    def test_timeadmin_group_permissions(self):
        group = "timeadmin"
        ug_info = self.get_user_group_ids(group)

        # Add a temporary user.
        user = "tmp_%s" % group
        cmd = "useradd %s -g %s" % (user, group)
        status, output = self.target.run(cmd)
        #self.assertEqual(status, 0, '\'%s\' failed\n' % cmd)

        errors = 0

        # ===========================
        # Test filesystem permissions
        # ===========================

        urls = {'/etc/systemd/timesyncd.conf.d/':'RWX',
                '/etc/systemd/timesyncd.conf.d/*':'RW'}

        for k in urls.keys():
            status = self.fs_permission_test(ug_info, k, urls[k])
            if status != 0:
                errors += 1
        self.assertEqual(errors, 0, 'Invalid filesystem permissions for %s!\n' % ug_info)

        # =======================
        # Test polkit permissions
        # =======================

        # Configure timesync via timedatectl
        cmd = "pkaction | grep org.freedesktop.timedate* | tr '\n' ',' | sed 's/,$//'"
        status, output = self.target.run(cmd)
        actions = "%s" % output

        # Create a user session to test polkit permissions in it.
        cmd = "su %s </dev/zero &>/dev/null &" % user
        status, output = self.target.run('%s' % cmd)
        self.assertEqual(status, 0, "'%s' failed\n" % cmd)

        for a in actions.split(','):
            cmd = "pkcheck -a %s -p $(pgrep -u %s)" % (a, user)
            status, output = self.target.run('%s' % cmd)
            if status != 0:
                bb.error ("polkit_permission_test (ug_info: %s, action_id: %s): %s - FAILED" % (ug_info, a, output))
                errors += 1
            else:
                bb.note ("polkit_permission_test (ug_info: %s, action_id: %s) - PASS" % (ug_info, a))

        # Cleanup/Remove the used user session.
        cmd = "kill -KILL $(pgrep -u %s)" % user
        status, output = self.target.run('%s' % cmd)
        self.assertEqual(status, 0, "'%s' failed\n" % cmd)



        # Remove the temporary user.
        cmd = "userdel -r %s" % user
        status, output = self.target.run(cmd)
        #self.assertEqual(status, 0, "'%s' failed\n" % cmd)

        self.assertEqual(errors, 0, "Invalid polkit permissions for %s!\n" % ug_info)

    ''' ======================================== '''

    def test_docker_readonly_group_permissions(self):
        group = "docker-readonly"
        ug_info = self.get_user_group_ids(group)

        # Add a temporary user.
        user = "tmp_%s" % group
        cmd = "useradd %s -g %s" % (user, group)
        status, output = self.target.run(cmd)
        #self.assertEqual(status, 0, '\'%s\' failed\n' % cmd)

        errors = 0

        # ===========================
        # Test filesystem permissions
        # ===========================

        urls = {'/run/docker.sock':'RW'}

        for k in urls.keys():
            status = self.fs_permission_test(ug_info, k, urls[k])
            if status != 0:
                errors += 1
        self.assertEqual(errors, 0, 'Invalid filesystem permissions for %s!\n' % ug_info)

        # ===================================
        # Test read/query all docker services
        # ===================================

        # Cleanup/Remove the used user session.
        cmd = "sudo -u %s /bin/sh -c 'docker ps'" % user
        status, output = self.target.run('%s' % cmd)
        self.assertEqual(status, 0, "'%s' failed\n" % cmd)

        # Cleanup/Remove the used user session.
        cmd = "sudo -u %s /bin/sh -c 'docker pull dummy'" % user
        status, output = self.target.run('%s' % cmd)
        self.assertIn("authorization denied", output, "'%s' failed\n" % cmd)



        # Remove the temporary user.
        cmd = "userdel -r %s" % user
        status, output = self.target.run(cmd)
        #self.assertEqual(status, 0, "'%s' failed\n" % cmd)

    ''' ======================================== '''
