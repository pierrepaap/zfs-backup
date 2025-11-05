#!/bin/bash

################################################
# Requirements:
# - 'backup' user on remote host
# - SSH keys set up for passwordless login to remote host for backup user
# - sudoers entry for backup user to allow zfs recv ans zfs list without password
#   e.g.: backup ALL=(ALL) NOPASSWD: /sbin/zfs recv, /sbin/zfs list
################################################

#
# global vars
#
if [ -f `dirname $0`/backup.vars ]
then
  . `dirname $0`/backup.vars
else
  echo "backup.vars missing"
  exit 1
fi

#
# args
#
if [ $# -ne 4 ]
then
  echo "We need 4 arguments <keyfile> <remotehost> <srcpool> <dstpool>. srcpool needs snapshots."
  fatal "We need 4 arguments <keyfile> <remotehost> <srcpool> <dstpool>". srcpool needs snapshots.
else
  KEY=$1
  REMOTE_BACKUP_HOST=$2
  SOURCE_POOL=$3
  BACKUP_POOL=$4
fi

#
# local vars
#
# log outputs from zfs commands
LOGFILE=${LOGDIR}/remote.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

log "*******************************"
log "Starting ZFS transfer of $SOURCE_POOL on `date '+%Y%m%d-%H%M'`"

SOURCE_FS_LIST=`${ZFS} list -H -o name -t filesystem -r ${SOURCE_POOL} | tail -n +2`
log "List of SOURCE_FS to transfer: ${SOURCE_FS_LIST}"

for SOURCE_FS in ${SOURCE_FS_LIST}
do
  log "    **************************"
  log " Starting transfer for ${SOURCE_FS}"
  # calculate dest FS name
  FS=`echo ${SOURCE_FS} | cut -f2- -d\/ `
  DEST_FS=${BACKUP_POOL}/${FS}
  log " Destination FS will be ${DEST_FS}"
  # look for previous snapshot
  PREVIOUS=`ssh backup@${REMOTE_BACKUP_HOST} -i ${KEY} "sudo ${ZFS} list -H -o name -t snapshot ${DEST_FS}| sort -r | head -1 | cut -f2 -d\@ " `
  if [ -z ${PREVIOUS} ]
  then
    log " We don't have a previous snapshot for ${FS}  => do it manually, skipping to next FS"
    continue
  else
    log " Previous date for ${DEST_FS} is ${PREVIOUS}"
  fi

  # transfer to remote host
  log " Starting the transfer"
  log "${ZFS} send -R -I ${SOURCE_FS}@${PREVIOUS} ${SOURCE_FS}@${TODAY03} | ssh backup@${REMOTE_BACKUP_HOST} -i ${KEY} sudo ${ZFS} recv -Fduv ${BACKUP_POOL} >> $LOGFILE 2>&1"
  ${ZFS} send -R -I ${SOURCE_FS}@${PREVIOUS} ${SOURCE_FS}@${TODAY03} | ssh backup@${REMOTE_BACKUP_HOST} -i ${KEY} sudo ${ZFS} recv -Fduv ${BACKUP_POOL} >> $LOGFILE 2>&1
  ##${ZFS} send -R -I ${SOURCE}@${PREVIOUS} ${SOURCE}@${TODAY03} | ${ZFS} recv -Fduv ${BACKUP_POOL} >> $LOGFILE 2>&1
  log " Transfer complete for ${SOURCE_FS}"
  log "    **************************"

done

log "End of transfer for ${SOURCE_POOL}"

