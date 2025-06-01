#!/bin/bash

##
##  This script depends on the backup.vars parameter file
##

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
# reusable functions
#
clean_logs()
{ 
  find $LOGDIR -mtime +120 -name "backup*.log*" -exec rm {} \;
}

#
# args
#
if [ $# -lt 1 ] || [ $# -ne 2 ] 
then
  echo "Usage: $0 <data_pool_name> <backup_pool_name>"
  exit 1
fi

DATA_POOL=$1
BACKUP_POOL=$2
SOURCE_POOL=`echo $DATA_POOL | cut -f1 -d\/`
SOURCE_FS=`echo $DATA_POOL | cut -f2 -d\/`

#
# local vars
#
LOGFILE=${LOGDIR}/backup.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

clean_logs
log "*******************************"
log "Starting ZFS backup of $DATA_POOL"

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
log "starting the backup"
##${ZFS} send -R -I ${DATA_POOL}@${PREVIOUS} ${DATA_POOL}@${NOW} | ssh root@$REMOTE_BACKUP_HOST ${ZFS} receive -Fduv $REMOTE_BACKUP_POOL
${ZFS} send -R -I ${DATA_POOL}@${PREVIOUS} ${DATA_POOL}@${NOW} | ${ZFS} receive -Fduv ${BACKUP_POOL} >> $LOGFILE 2>&1
 
log " backup complete destroying previous snapshot (if it's not the last one...)"
NBR_BACKUP=`${ZFS} list -r -H -t snapshot ${BACKUP_POOL} | grep "${BACKUP_POOL}\@" | wc -l`
if [ ${NBR_BACKUP} -gt 1 ]
then 
  ${ZFS} destroy -r ${DATA_POOL}@${PREVIOUS} || fatal "cannot destroy previous snapshot aborting"
fi

log "end of backup"

