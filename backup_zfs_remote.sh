#!/bin/bash

################################################
# Requirements:
# - backup user on remote host
# - SSH keys set up for passwordless login to remote host for backup user
################################################

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
if [ $# -ne 4 ]
then
  echo "We need 4 arguments <keyfile> <remotehost> <srcpool> <dstpool>. srcpool needs snapshots."
  fatal "We need 4 arguments <keyfile> <remotehost> <srcpool> <dstpool>". srcpool needs snapshots.
else
  KEY=$1
  REMOTE_BACKUP_HOST=$2
  SOURCE_POOL=$3
  BACKUP_POOL=$4
fi

#
# local vars
#
# log outputs from zfs commands
LOGFILE=${LOGDIR}/remote.`date +%Y%m%d.%H%M`.log
KEY=

##########
# MAIN 
##########

log "*******************************"
log "Starting ZFS transfer of $SOURCE_POOL on `date '+%Y%m%d-%H%M'`"

# look for previous snapshot
PREVIOUS=`${ZFS} list -H -o name -t snapshot ${SOURCE_POOL}| sort -r | head -1 | cut -f2 -d\@ `
if [ -z ${PREVIOUS} ]
then
  log "We don't have a previous snapshot => do it manually, exiting"
  exit 3
else
  log "Previous date is ${PREVIOUS}"
fi

# transfer to remote host
log "Starting the transfer"
${ZFS} send -R -I ${SOURCE_POOL}@${PREVIOUS} ${SOURCE_POOL}@${TODAY} | ssh backup@${REMOTE_BACKUP_HOST} -i ${KEY} ${ZFS} receive -Fduv $BACKUP_POOL
##${ZFS} send -R -I ${SOURCE}@${PREVIOUS} ${SOURCE}@${TODAY} | ${ZFS} receive -Fduv ${BACKUP_POOL} >> $LOGFILE 2>&1
log " Transfer complete"

log "End of transfer"

