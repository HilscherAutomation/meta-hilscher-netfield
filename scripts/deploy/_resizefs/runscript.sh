#!/bin/sh

source ./common

log "$(date -u +'%Y%m%d-%H%M%S') (utc):"
log "########################################"
log "#                                      #"
log "#       Resizing data partition        #"
log "#                                      #"
log "########################################"
log ""

# Resize backup partition
e2fsck -p -f /dev/mapper/data-backup 2>&1 | tee -a $logfile
resize2fs /dev/mapper/data-backup 128M 2>&1 | tee -a $logfile
lvreduce -f -L 128M /dev/mapper/data-backup 2>&1 | tee -a $logfile

e2fsck -p -f /dev/mapper/data-data 2>&1 | tee -a $logfile
lvextend -l +100%FREE /dev/mapper/data-data 2>&1 | tee -a $logfile
resize2fs /dev/mapper/data-data 2>&1 | tee -a $logfile

# Delete firmware file, otherwise resizing will be tried every reboot
rm -f $apifile

# Copy update log to system partition
mp=$(mktemp -d)
mount $(blkid -L system) $mp
cat $logfile >> $mp/last_update.log
umount $mp
rmdir $mp
