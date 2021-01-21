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
  exit 2
fi

#
# reusable functions
#
check_pool()
{
  for fs_name in ${BKP_LIST}
  do
#    echo "   testing $1 against backed up fs $fs_name"
    if [ $1 == $fs_name ]
    then
      IS_OK=1
      return
    else
      IS_OK=0
    fi
  done
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

#
# local vars
#
LOGFILE=/zdocs/server/log/backup_init.`date +%Y%m%d.%H%M`.log

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

#look for unique snapshot name(s)/date(s)
log "Retrieving the list of unique snapshots name(s)/date(s)"
LAST_SNAP=`${ZFS} list -H -r -o name -t snapshot ${SOURCE_POOL} | sort -r | cut -f2 -d\@ | sort -u | tail -1`
log "Last snap : ${LAST_SNAP}"

log "Start backup of ${SOURCE}@${SNAP}"
${ZFS} send -R ${SOURCE}@${SNAP} | ${ZFS} recv -Fduv ${BACKUP_POOL} >> ${LOGFILE} 2>&1
