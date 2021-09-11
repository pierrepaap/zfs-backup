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
  log "We need 2 arguments <datapool/fs> <backup_pool>"
  fatal "NB : This script assumes <backup_pool> is created and empty"
else
  DATA_FS=$1
  BACKUP_POOL=$2
  SOURCE_POOL=`echo $DATA_FS | cut -f1 -d\/`
  SOURCE_FS=`echo $DATA_FS | cut -f2 -d\/`
fi

#
# local vars
#
LOGFILE=${LOGDIR}/backup_init.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

echo "Logs can be found in ${EXECLOGFILE} and ${LOGFILE}"

# Check if FS exists on backup pool
EXISTS_BKP_FS=`${ZFS} list -H | grep ^${BACKUP_POOL}/${SOURCE_FS} | wc -l `
if [ ${EXISTS_BKP_FS} -ne 0 ]
then
  fatal "Pool ${BACKUP_POOL} already has ${SOURCE_FS} filesystem, cannot proceed with init"
fi

# Check source pool status
EXISTS_SRC_FS=`${ZFS} list -H | grep ^${SOURCE_POOL}/${SOURCE_FS} | wc -l `
if [ ${EXISTS_SRC_FS} -eq 0 ]
then
  fatal "Source FS ${SOURCE_POOL}/${SOURCE_FS} does not exist, nothing to backup"
else
  EXISTS_SRC_SNAP=`${ZFS} list -H -r -t snapshot ${SOURCE_POOL} | wc -l`
  if [ ${EXISTS_SRC_SNAP} -eq 0 ]
  then
    fatal "There are not snapshot on ${SOURCE_POOL}/${SOURCE_FS}. Relaunch after snapshot have been created."
  fi
fi

# Backup each fs separately
SRC_FS_LIST=`${ZFS} list -H -r -t snapshot ${SOURCE_POOL} | cut -f1 -d\@ `
BKP_FS_LIST=`${ZFS} list -H -r -t snapshot ${BACKUP_POOL} | cut -f1 -d\@  | cut -f2 -d\/ `
for fs in ${SRC_FS_LIST}
do
  CUR_FS=`echo $fs | cut -f2 -d\/ ` 

  log "Start backup of $fs"
  (${ZFS} send -v ${fs}@${TODAY} | ${ZFS} recv -Fduv ${BACKUP_POOL}) >> ${LOGFILE} 2>&1 &
  disown
  sleep 10
done

