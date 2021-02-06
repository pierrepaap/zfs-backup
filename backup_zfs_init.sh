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
  echo "We need 2 arguments <data_pool> <backup_pool> \n"
  exit 2
else
  DATA_POOL=$1
  BACKUP_POOL=$2
  SOURCE_POOL=`echo $DATA_POOL | cut -f1 -d\/`
  SOURCE_FS=`echo $DATA_POOL | cut -f2 -d\/`
fi

#
# local vars
#
LOGFILE=${LOGDIR}/backup_init.`date +%Y%m%d.%H%M`.log

#
# reusable functions
#
check_pool()
{
  for fs_name in ${BKP_LIST}
  do
#    echo "   testing $1 against backed up fs $fs_name"
    if [ $1 == $fs_name ]
    then
      IS_OK=1
      return
    else
      IS_OK=0
    fi
  done
}

##########
# MAIN 
##########

# Check backup pool status and recreate it if needed
EXISTS_BKP_FS=`${ZFS} list -H ${BACKUP_POOL} | grep ^${BACKUP_POOL} | wc -l `
if [ ${EXISTS_BKP_FS} -eq 0 ]
then
  if [ `${ZPOOL} list -H | grep ^${BACKUP_POOL} | grep ONLINE | wc -l ` -eq 0 ]
  then
    echo " destroying pool ${BACKUP_POOL}"
    ${ZPOOL} destroy ${BACKUP_POOL}
    echo " recreating pool ${BACKUP_POOL}"
    ${ZPOOL} create ${BACKUP_POOL} /dev/${BACKUP_DEVICE}
  fi
fi

##echo "FS LIST : ${FS_LIST}"
##echo "--------------------"

# backup each pool separately
for pool in ${FS_LIST}
do
  CUR_FS=`echo $pool | cut -f2 -d\/ ` 
  check_pool ${CUR_FS}

  if [ ${pool} != $DATA_POOL -a ${IS_OK} -eq 0 ]
  then 
    echo "Start backup of $pool"
    ${ZFS} send -v ${pool}@${TODAY} | ${ZFS} recv -Fduv ${BACKUP_POOL}
    sleep 120
  fi
done

