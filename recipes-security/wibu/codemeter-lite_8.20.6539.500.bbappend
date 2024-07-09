FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

SRC_URI:append = " file://codemeter_use_persistent_dir.patch"

do_install:append() {
    # Symlink data directory to nvd directory
    for dir in Backup CmAct CmCloud NamedUser; do
        rmdir ${D}/var/lib/CodeMeter/$dir
        ln -s /mnt/backup/nvd/codemeter/$dir ${D}/var/lib/CodeMeter/$dir
    done
}
