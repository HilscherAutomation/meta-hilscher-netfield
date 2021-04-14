# Manpage generation requires pod2man which is not a mandatory
# host tool anymore and comes from yocto's perl-native now
# See: https://git.yoctoproject.org/cgit.cgi/poky/commit/meta/conf/bitbake.conf?id=5249a8a3d505e277b73e51ac0efe33512a71b58b
inherit perlnative
