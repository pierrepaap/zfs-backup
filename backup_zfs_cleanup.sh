#!/bin/bash
##set -x

# global vars
if [ -f `dirname $0`/backup.vars ]
then
  . `dirname $0`/backup.vars
else
  echo "backup.vars missing"
  exit 2
fi

# args
if [ $# -ne 2 ]
then
  echo "We need 2 arguments <data_pool> <backup_pool> \n"
  exit 1
fi

if [ ! -z $1 ]
then
  DATA_POOL=$1
fi

if [ ! -z $2 ]
then
  BACKUP_POOL=$2
fi

# local vars
EXECLOGFILE=${LOGDIR}/cleanup.`date +%Y%m%d.%H%M`.log
TEMPFILE=${LOGDIR}/temp_`basename $0`_$$

# reusable functions
clean_logs()
{ 
  find $LOGDIR -mtime +${LOG_RETENTION} -name "cleanup.*.log*" -exec rm {} \;
}

##########
# MAIN 
##########

clean_logs

log "Pools : backup - $BACKUP_POOL  /  data - $DATA_POOL"

for POOL in $BACKUP_POOL $DATA_POOL
do
  log " "
  log "************************ POOL ${POOL} *************************"
  log "Starting ZFS cleanup of ${POOL} on `date '+%Y%m%d-%H%M'`"


  # look for last SNAPS_TO_KEEP backup(s)
  PREVIOUS=`${ZFS} list -H -r -o name -t snapshot ${POOL} | sort -r | head -$SNAPS_TO_KEEP | cut -f2 -d\@ | sort -u`
##  log "last backup(s) : $PREVIOUS"
  if [ -z "${PREVIOUS}" ]
  then
    log "We don't have a backup => don't cleanup, skipping"
    continue
  else
    log "last backup(s) : ${PREVIOUS}"
  fi

  log "${POOL} - Retrieving list of ALL snapshots (of the top zfs) and keeping the PREVIOUS backups"
  TOP_SNAPS=`${ZFS} list -H -r -o name -t snapshot ${POOL} | grep -v \/ | sort -r `
  ###TOP_SNAPS=`echo $SNAPS | sed -e "s,/[a-z]*\@,\@,g"`
  if [ -z "$TOP_SNAPS" ]
  then
    log "No top zfs snapshots, retrieveing all other snapshots"
    SNAPS=`${ZFS} list -H -r -o name -t snapshot ${POOL} | sort -r `
  else
    SNAPS=$TOP_SNAPS
  fi

  # Filtering out previous backups (as selected above)
  # by removing them from SNAPS list
  log "Exclude backups to be kept"
  for previous in $PREVIOUS
  do
    if [ ! -z "$TOP_SNAPS" ]
    then
      SNAPS=`echo $SNAPS | sed -e "s,${POOL}\@${previous},,g"`
    else 
      FILTER_SNAPS=
      for snap in $SNAPS
      do
        FILTER_SNAPS="$FILTER_SNAPS `echo $snap | grep -v $previous `"
      done
      SNAPS=$FILTER_SNAPS
    fi
  done

  log "Deleting extra snapshots"
  # to avoid useless error message
  touch $TEMPFILE
  # Deleting snaps listed in $SNAPS
  for snap in $SNAPS
  do
    NB=`grep $snap $TEMPFILE | wc -l`
    if [ $NB -eq 0 ]
    then
      log "Deleting $snap"
      ${ZFS} destroy -r $snap || fatal "cannot destroy snapshot $snap"
      echo $snap >> $TEMPFILE
    fi
  done

  cat $TEMPFILE
  rm $TEMPFILE

  log "end of cleanup"

done
