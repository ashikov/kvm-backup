#! /bin/bash

CURRENT_DATE=`date +"%Y%m%d_%H%M%S"`
VM_NAME="win2k8r2"
VM_STATUS=`virsh domstate $VM_NAME`
DOMAIN_DIR="/mnt/md0/kvm"
MAIN_BACKUP_DIR="/mnt/backup_sde1/kvm/$VM_NAME"
CURRENT_BACKUP_DIR=$MAIN_BACKUP_DIR/$CURRENT_DATE

# backup server config
BACKUP_SERVER_IP="x.x.x.x"
SSH_USER="x"
REMOTE_BACKUP_DIR="guests/$VM_NAME"

mkdir $CURRENT_BACKUP_DIR

counter=0
while [ "$VM_STATUS" == "running" ]; do
  echo "$VM_NAME is $VM_STATUS"
  virsh shutdown $VM_NAME
  sleep 10
  VM_STATUS=`virsh domstate $VM_NAME`

  counter=$((counter + 1)) # sending email if its runnig too long
  if [ counter == 10 ]; then
    echo -e "Subject: KVM backup error - IO\n\nVM $VM_NAME does not shutdown" | ssmtp errors@tdom.info
    break
  fi
done

echo "$VM_NAME is $VM_STATUS"

echo "saving disk metadata"
virsh domblkinfo $VM_NAME $DOMAIN_DIR/$VM_NAME.qcow2 > $CURRENT_BACKUP_DIR/$VM_NAME
virsh vol-pool $DOMAIN_DIR/$VM_NAME.qcow2 >> $CURRENT_BACKUP_DIR/$VM_NAME
echo "$DOMAIN_DIR/$VM_NAME.qcow2" >> $CURRENT_BACKUP_DIR/$VM_NAME
echo "metadata successfully saved"

echo "compressing disk file"
dd if=$DOMAIN_DIR/$VM_NAME.qcow2 | gzip -kc -3 > $CURRENT_BACKUP_DIR/$VM_NAME.qcow2.gz
echo "done"

virsh start $VM_NAME

echo "$VM_NAME is $VM_STATUS"

echo "create archive file from backup directory"
tar -cvf $MAIN_BACKUP_DIR/$CURRENT_DATE.tar.gz $CURRENT_BACKUP_DIR/

echo "sending data to backup-server"
scp $MAIN_BACKUP_DIR/$CURRENT_DATE.tar.gz $SSH_USER@$BACKUP_SERVER_IP:~/$REMOTE_BACKUP_DIR/

echo "deleting current backup from local storage"
rm -rvf $CURRENT_BACKUP_DIR
rm -rvf $MAIN_BACKUP_DIR/$CURRENT_DATE.tar.gz

echo "backup completed"


