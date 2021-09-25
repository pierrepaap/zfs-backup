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
  SOURCE=$1
  BACKUP_POOL=$2
  SOURCE_POOL=`echo $SOURCE | cut -f1 -d\/`
  SOURCE_FS=`echo $SOURCE | cut -f2 -d\/`
  if [ `echo $SOURCE | grep / | wc -l` -eq 0 ]
  then
    echo "No FS specified in ${SOURCE}"
    fatal "No FS specified in ${SOURCE}"
  fi
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

#look for unique snapshot name(s)/date(s)
log "Retrieving the list of unique snapshots name(s)/date(s)"
SNAPS=`${ZFS} list -H -r -o name -t snapshot ${SOURCE_POOL} | sort -r | cut -f2 -d\@ | sort -u`
log "List : ${SNAPS}"

for snap in ${SNAPS}
do
  SNAPS=`echo $SNAPS | sed -e "s,${SOURCE_POOL}\@${snap},,g"`
  log "Start backup of ${SOURCE_POOL}@${snap}"
  ${ZFS} send -R ${SOURCE_POOL}@${snap} | ${ZFS} recv -Fduv ${BACKUP_POOL} >> ${LOGFILE} 2>&1
done
