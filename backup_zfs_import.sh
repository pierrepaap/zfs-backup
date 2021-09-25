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
LOGFILE=${LOGDIR}/import.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

log "Importing $DATA_POOL"
${ZPOOL} import ${DATA_POOL} >> ${LOGFILE} 2>&1

sleep 10
if [ `${ZPOOL} list | grep ^${DATA_POOL} | wc -l ` -eq 1 ]
then
  log "Import OK"
else
  echo "Import failed, check logs at ${LOGFILE}"
  fatal "Import failed, check logs at ${LOGFILE}"
fi
