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
  echo "We need 2 arguments <datapool/fs> <backup_pool> \n"
  echo "This script assumes <backup_pool is created and empty\n"
  exit 2
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

# Check backup pool status
EXISTS_BKP_FS=`${ZFS} list -H ${BACKUP_POOL} | grep ^${BACKUP_POOL} | wc -l `
if [${EXISTS_BKP_FS} -neq 0]
then
  log "Pool ${BACKUP_POOL} is not empty, cannot proceed"
  exit 3
fi

# Check source pool status
EXISTS_SRC_FS=`${ZFS} list -H ${SOURCE_POOL} | grep ^${SOURCE_POOL} | wc -l `
if [${EXISTS_SRC_FS} -eq 0]
then
  log "Pool ${SOURCE_POOL} is empty, nothing to backup"
  exit 0
else
  EXISTS_SRC_SNAP=`${ZFS} list -H -r -t snapshot ${SOURCE_POOL} | wc -l`
  if [${EXISTS_SRC_SNAP} -eq 0]
  then
    # TODO
    # crete a ref in backup.vars for snapsshot script
    # execute snapshot script for each FS
  fi
fi

# Backup each fs separately
SRC_FS_LIST=`${ZFS} list -H -r -t snapshot ${SOURCE_POOL} | cut -f1 -d\@ `
BKP_FS_LIST=`${ZFS} list -H -r -t snapshot ${BACKUP_POOL} | cut -f1 -d\@  | cut -f2 -d\/ `
for fs in ${SRC_FS_LIST}
do
  CUR_FS=`echo $fs | cut -f2 -d\/ ` 

  echo "Start backup of $fs"
  (${ZFS} send -v ${fs}@${TODAY} | ${ZFS} recv -Fduv ${BACKUP_POOL}) &
  disown
  sleep 10
done

