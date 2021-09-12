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
if [ $# -ne 1 ]
then
  echo "We need 1 argument: <pool> to create snapshots for its filesystems"
  fatal "We need 1 argument: <pool> to create snapshots for its filesystems"
else
  DATA_POOL=$1
fi
log "--- $DATA_POOL ---"

#
# local vars
#
# logging output of zfs snapshot command
LOGFILE=${LOGDIR}/snap.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

log "*******************************"
log "Starting ZFS snapshot of $DATA_POOL on `date '+%Y%m%d-%H%M'`"

# create today snapshot
if ${ZFS} list -H -o name -t snapshot | sort | grep "${DATA_POOL}@${TODAY}$" >> $LOGFILE 2>&1
then
  log " Snapshot ${DATA_POOL}@${TODAY} already exists"
else
  log " Taking todays snapshot ${DATA_POOL}@${TODAY}"
  ${ZFS} snapshot -r ${DATA_POOL}@${TODAY} >> $LOGFILE 2>&1
fi  

log "End of snapshot"

