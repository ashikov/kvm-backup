#!/usr/bin/env bash

CURRENT_DATE=$(date +"%H%M%S_%d%m%Y")
BACKUP_DIR="/mnt/backup_sde1"

# backup server config
BACKUP_SERVER_IP="x.x.x.x"
SSH_USER="x"
REMOTE_BACKUP_DIR="host"

printf "Compressing system files\\n\\n"
sudo tar cvpzf "$BACKUP_DIR/ubuntu_server_$CURRENT_DATE.tgz" --exclude=/home --exclude=/media --exclude=/dev --exclude=/mnt --exclude=/proc --exclude=/sys --exclude=/tmp / > /dev/null

printf "Sending data to backup-server\\n\\n"
scp "$BACKUP_DIR/ubuntu_server_$CURRENT_DATE.tgz" $SSH_USER@$BACKUP_SERVER_IP:~/$REMOTE_BACKUP_DIR/

printf "Deleting current backup from local storage\\n\\n"
rm -rvf "$BACKUP_DIR/ubuntu_server_$CURRENT_DATE.tgz"

printf "Completed\\n\\n"