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
  if [ $# -eq 1 ]
  then
    RETENTION=$1
  else
    RETENTION=120
  fi

  find $LOGDIR -mtime +"$RETENTION" -name "cleanup.*.log*" -exec rm {} \;
}


#
# args
#
if [ $# -gt 1 ]
then
  echo "Usage: $0 [retention days]"
  exit 1
fi

#
# local vars
#
EXECLOGFILE=${LOGDIR}/log_cleanup.`date +%Y%m%d.%H%M`.log

##########
# MAIN 
##########

clean_logs $1