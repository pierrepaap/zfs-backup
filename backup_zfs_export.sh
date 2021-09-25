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
  echo "Usage: We need 1 argument: <pool>"
  fatal "We need 1 argument: <pool>"
else
  DATA_POOL=$1
fi

#
# local vars
#
# logging output of zpool command
LOGFILE=${LOGDIR}/export.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

log "Exporting $DATA_POOL"
${ZPOOL} export ${DATA_POOL} >> ${LOGFILE} 2>&1

sleep 10
if [ `${ZPOOL} list | grep ^${DATA_POOL} | wc -l` -eq 0 ]
then
  log "Export OK"
else
  echo "Export failed, check logs at ${LOGFILE}"
  fatal "Export failed, check logs at ${LOGFILE}"
fi
