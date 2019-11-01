#!/usr/bin/env bash

CURRENT_DATE=$(date +"%H%M%S_%d%m%Y")
VM_NAME="kvmserv-io-1"
BACKUP_DIR="/mnt/backups"
LV_NAME="kvmserv-io-1-lvm-disk-1"
LV_PATH="/dev/vg1-kvm/kvmserv-io-1-lvm-disk-1"
COW_TABLE_SIZE="20G"

# Backup-server config
BACKUP_SERVER_IP="ip-address"
SSH_USER="username"
REMOTE_BACKUP_DIR="guests/$VM_NAME"

printf "\\nSaving disk metadata and XML-config\\n\\n"
virsh domblkinfo $VM_NAME $LV_PATH > "$BACKUP_DIR/$CURRENT_DATE-$VM_NAME"
virsh vol-pool $LV_PATH >> "$BACKUP_DIR/$CURRENT_DATE-$VM_NAME"
echo "$LV_PATH" >> "$BACKUP_DIR/$CURRENT_DATE-$VM_NAME"
printf "Metadata successfully saved\\n\\n"
virsh dumpxml $VM_NAME > "$BACKUP_DIR/$CURRENT_DATE-$VM_NAME.xml"
printf "XML-config successfully saved\\n\\n"

printf "Saving VM state\\n"
virsh save $VM_NAME "$BACKUP_DIR/$CURRENT_DATE-$VM_NAME.vmstate" --running
printf "State successfully saved\\n\\n"

printf "Creating LVM-snapshot\\n\\n"
lvcreate -s -n "$LV_NAME"_snap -L$COW_TABLE_SIZE $LV_PATH

printf "\\nRestoring VM \\n\\n"
virsh restore "$BACKUP_DIR/$CURRENT_DATE-$VM_NAME.vmstate"

printf "Compressing snapshot\\n\\n"
dd if="$LV_PATH"_snap | gzip -ck -3 > "$BACKUP_DIR/$CURRENT_DATE-$LV_NAME.gz"
printf "Done\\n\\n"

printf "\\nRemoving snapshot\\n\\n"
lvremove --force "$LV_PATH"_snap

printf "Packing backup files in tar\\n\\n"
tar -cvf "$BACKUP_DIR/$CURRENT_DATE-$VM_NAME.tar.gz" $BACKUP_DIR/

printf "Sending data to backup-server\\n\\n"
scp "$BACKUP_DIR/$CURRENT_DATE-$VM_NAME.tar.gz" $SSH_USER@$BACKUP_SERVER_IP:~/$REMOTE_BACKUP_DIR/

printf "Deleting current backup files from local storage\\n\\n"
rm -rvf "${BACKUP_DIR:?}/"*

printf "\\nBackup completed\\n\\n"