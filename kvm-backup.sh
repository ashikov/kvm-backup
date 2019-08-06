#! /bin/bash
# virsh destroy win2k8r2 - if it didnt shutdown

CURRENT_DATE=`date +"%Y%m%d_%H%M%S"`
VM_NAME="win2k8r2"
VM_STATUS=`virsh domstate $VM_NAME`
DOMAIN_DIR="/mnt/md0/kvm"
MAIN_BACKUP_DIR="/mnt/backup_sde1/kvm/win2k8r2"
CURRENT_BACKUP_DIR=$MAIN_BACKUP_DIR/$CURRENT_DATE

mkdir $CURRENT_BACKUP_DIR

while [ "$VM_STATUS" == "running" ]; do
  echo "$VM_NAME is $VM_STATUS"
  virsh shutdown $VM_NAME
  sleep 8
  VM_STATUS=`virsh domstate $VM_NAME`
done

echo "$VM_NAME is $VM_STATUS"

echo "saving disk metadata"
virsh domblkinfo $VM_NAME $DOMAIN_DIR/$VM_NAME.qcow2 > $CURRENT_BACKUP_DIR/$VM_NAME
virsh vol-pool $DOMAIN_DIR/$VM_NAME.qcow2 >> $CURRENT_BACKUP_DIR/$VM_NAME
echo "$DOMAIN_DIR/$VM_NAME.qcow2" >> $CURRENT_BACKUP_DIR/$VM_NAME
echo "metadata successfully saved"

echo "compressing disk file"

dd if=$DOMAIN_DIR/$VM_NAME.qcow2 | gzip -kc -3 > $CURRENT_BACKUP_DIR/$VM_NAME.qcow2.gz

echo "Done"

virsh start $VM_NAME

echo "$VM_NAME is $VM_STATUS"

echo "backup completed"

