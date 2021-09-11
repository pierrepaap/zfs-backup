#!/bin/bash

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
if [ $# -ne 2 ]
then
  echo "We need 2 arguments <datapool/fs> <backup_pool>"
  fatal "We need 2 arguments <datapool/fs> <backup_pool>"
else
  SOURCE=$1
  BACKUP_POOL=$2
  SOURCE_POOL=`echo $SOURCE | cut -f1 -d\/`
  SOURCE_FS=`echo $SOURCE | cut -f2 -d\/`
fi

#
# local vars
#
# log outputs from zfs commands
LOGFILE=${LOGDIR}/backup.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

log "*******************************"
log "Starting ZFS backup of $SOURCE on `date '+%Y%m%d-%H%M'`"

# look for previous snapshot
PREVIOUS=`${ZFS} list -H -r -o name -t snapshot ${BACKUP_POOL}/${SOURCE_FS} | sort -r | head -1 | cut -f2 -d\@ `
if [ -z ${PREVIOUS} ]
then
  log "We don't have a previous snapshot => do it manually, exiting"
  exit 3
else
  log "Previous date is ${PREVIOUS}"
fi

# backup to USB drive
log "Starting the backup"
##${ZFS} send -R -I ${SOURCE}@${PREVIOUS} ${SOURCE}@${TODAY} | ssh root@$REMOTE_BACKUP_HOST ${ZFS} receive -Fduv $REMOTE_BACKUP_POOL
${ZFS} send -R -I ${SOURCE}@${PREVIOUS} ${SOURCE}@${TODAY} | ${ZFS} receive -Fduv ${BACKUP_POOL} >> $LOGFILE 2>&1
log " Backup complete"

log "End of backup"

