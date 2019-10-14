#!/usr/bin/env bash

CURRENT_DATE=$(date +"%H%M%S_%d%m%Y")
VM_NAME="kvmserv-a-1"
BACKUP_DIR="/mnt/backups"
LV_NAME="kvmserv-a-1-lvm-disk-1"
LV_PATH="/dev/vg-libvirt/kvmserv-a-1-lvm-disk-1"
COW_TABLE_SIZE="32G"

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

