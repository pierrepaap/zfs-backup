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
clean_logs()
{ 
  find $LOGDIR -mtime +120 -name "cleanup.*.log*" -exec rm {} \;
}


#
# args
#
if [ $# -lt 1 ] || [ $# -gt 2 ] 
then
  echo "Usage: $0 <pool_name> [nbr snap to keep]"
  exit 1
fi

#
# local vars
#
POOL=$1
if [ $# -eq 2 ]
then
  SNAP_RETENTION=$2
else
  SNAP_RETENTION=$SNAPS_TO_KEEP
fi
EXECLOGFILE=${LOGDIR}/cleanup.`date +%Y%m%d.%H%M`.log
TEMPFILE=${LOGDIR}/temp_`basename $0`_$$

##########
# MAIN 
##########

clean_logs

log "Pool : $POOL"


log " "
log "************************ POOL ${POOL} *************************"
log "Starting ZFS cleanup of ${POOL} on `date '+%Y%m%d-%H%M'`"


# look for last SNAP_RETENTION backup(s)
PREVIOUS=`${ZFS} list -H -r -o name -t snapshot ${POOL} | sort -r | head -$SNAP_RETENTION | cut -f2 -d\@ | sort -u`
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
if [ -z "$TOP_SNAPS" ]
then
  log "No top zfs snapshots, retrieving all other snapshots"
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
