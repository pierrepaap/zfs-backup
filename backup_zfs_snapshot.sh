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
  find $LOGDIR -mtime +120 -name "snap.*.log*" -exec rm {} \;
}

#
# args
#
if [ $# -lt 1 ] || [ $# -ne 1 ] 
then
  echo "Usage: $0 <data_pool_name> <backup_pool_name>"
  exit 1
fi

DATA_POOL=$1
echo "--- $DATA_POOL ---"

#
# local vars
#
LOGFILE=${LOGDIR}/snap.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

log "*******************************"
log "Starting ZFS snapshot @${NOW} of $DATA_POOL" 

# create snapshot
if ${ZFS} list -H -o name -t snapshot | sort | grep "${DATA_POOL}@${NOW}$" >> $LOGFILE 2>&1
then
  log " Snapshot ${DATA_POOL}@${NOW} already exists"
else
  log " Taking snapshot ${DATA_POOL}@${NOW}"
  ${ZFS} snapshot -r ${DATA_POOL}@${NOW} >> $LOGFILE 2>&1
fi  

log "End of snapshot"

