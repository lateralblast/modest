#!/usr/bin/bash

BASE_DIR="/export/repo"
REPO_ISO=$1
SOL_UPD=`echo $REPO_ISO | awk -F/ '{print $NF}' | cut -f2 -d_ | cut -f1 -d-`
REPO_DIR="$BASE_DIR/sol_11_$SOL_UPD"
CD_MOUNT="/mnt/cdrom"

if [ `echo $SOL_UPD |grep "^[0-9]"` ]; then
  mkdir $CD_MOUNT
  zfs create rpool$BASE_DIR
  zfs create rpool$REPO_DIR
  mount -F hsfs $REPO_ISO $CD_MOUNT
  rsync -a $CD_MOUNT/repo/* $REPO_DIR
  umount $CD_MOUNT
  pkgrepo -s $REPO_DIR refresh
  pkg set-publisher -G '*' -g $REPO_DIR solaris
fi