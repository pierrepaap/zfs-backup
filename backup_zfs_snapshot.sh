#!/bin/bash

# global vars
if [ -f `dirname $0`/backup.vars ]
then
  . `dirname $0`/backup.vars
else
  echo "backup.vars missing"
  exit 1
fi

# local vars
LOGFILE=${LOGDIR}/snap.`date +%Y%m%d.%H%M`.log

# reusable functions
clean_logs()
{ 
  find $LOGDIR -mtime +${LOG_RETENTION} -name "snap.*.log*" -exec rm {} \;
}

# args
if [ ! -z $1 ]
then
  DATA_POOL=$1
fi
echo "--- $DATA_POOL ---"

##########
# MAIN 
##########

clean_logs
log "*******************************"
log "Starting ZFS snapshot of $DATA_POOL on `date '+%Y%m%d-%H%M'`"

# create today snapshot
if ${ZFS} list -H -o name -t snapshot | sort | grep "${DATA_POOL}@${TODAY}$" >> $LOGFILE 2>&1
then
  log " snapshot, already exists"
else
  log " taking todays snapshot, ${DATA_POOL}@${TODAY}"
  ${ZFS} snapshot -r ${DATA_POOL}@${TODAY} >> $LOGFILE 2>&1
fi  

log "end of snapshot"

