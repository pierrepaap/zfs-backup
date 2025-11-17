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
LOGFILE=/zmedia/server/log/backup_init.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

log "*******************************"
log "Starting ZFS initial backup of ${DATA_POOL} to ${BACKUP_POOL}"
log "Logs can be found in ${EXECLOGFILE} and ${LOGFILE}"

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
  EXISTS_SRC_SNAP=`${ZFS} list -H -t snapshot ${SOURCE_POOL}/${SOURCE_FS} | wc -l`
  if [ ${EXISTS_SRC_SNAP} -eq 0 ]
  then
    fatal "There are no snapshot on ${SOURCE_POOL}/${SOURCE_FS}. Relaunch after snapshot have been created."
  fi
fi

#look for unique snapshot name(s)/date(s)
log "Retrieving the list of unique snapshots name(s)/date(s)"
LAST_SNAP=`${ZFS} list -H -r -o name -t snapshot ${SOURCE_POOL}/${SOURCE_FS} | sort -r | cut -f2 -d\@ | sort -u | tail -1`
log "Last snap : ${LAST_SNAP}"

log "Start backup of ${SOURCE}@${LAST_SNAP}"
${ZFS} send -R ${SOURCE}@${LAST_SNAP} | ${ZFS} recv -Fduv ${BACKUP_POOL} >> ${LOGFILE} 2>&1
