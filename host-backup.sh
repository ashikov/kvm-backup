#!/usr/bin/env bash

CURRENT_DATE=`date +"%Y%m%d_%H%M%S"`
MAIN_BACKUP_DIR="/mnt/backup_sde1"

# backup server config
BACKUP_SERVER_IP="x.x.x.x"
SSH_USER="x"
REMOTE_BACKUP_DIR="host"

echo "hello, bro!"
echo "compressing system files"
sudo tar cvpzf $MAIN_BACKUP_DIR/ubuntu_server_$CURRENT_DATE.tgz --exclude=/media --exclude=/proc --exclude=/lost+found --exclude=/mnt --exclude=/sys /

echo "sending data to backup-server"
scp $MAIN_BACKUP_DIR/ubuntu_server_$CURRENT_DATE.tgz $SSH_USER@$BACKUP_SERVER_IP:~/$REMOTE_BACKUP_DIR/

echo "deleting current backup from local storage"
rm -rvf $MAIN_BACKUP_DIR/ubuntu_server_$CURRENT_DATE.tgz

echo "backup completed"