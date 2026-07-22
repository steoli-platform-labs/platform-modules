#!/bin/bash

# Enable trace
set -x
exec 2>>/var/log/root-init.log

# Init vars
EXPECTED_DEVICE="/dev/sdf"
TARGET_VOLUME=""

export DEBIAN_FRONTEND=noninteractive

# Install required packages
apt-get update -y
apt-get -y install nvme-cli nfs-common

# Activate LVM volume groups
vgchange -ay

echo "Looking for AWS-mapped device $${EXPECTED_DEVICE}"

# Wait until the intended data disk is attached and visible
for i in $(seq 30)
do
  for VOLUME in /dev/nvme*n1
  do
    [ -b "$VOLUME" ] || continue

    echo "Inspecting volume $VOLUME"
    MAPPED_DEVICE=$(nvme id-ctrl -V "$VOLUME" 2>/dev/null | sed -n 's/.*"\(\/dev\/\)\?\(sd[a-z][a-z0-9]*\).*/\/dev\/\2/p')
    echo "$VOLUME maps to $MAPPED_DEVICE"

    if [[ "$MAPPED_DEVICE" == "$EXPECTED_DEVICE" ]]
    then
      TARGET_VOLUME="$VOLUME"
      echo "Selected target volume: $TARGET_VOLUME"
      break 2
    fi
  done

  echo "Did not find $${EXPECTED_DEVICE} yet, sleeping 5 seconds..."
  sleep 5
done

if [[ -z "$TARGET_VOLUME" ]]
then
  echo "ERROR: Could not find the NVMe device mapped to $${EXPECTED_DEVICE}"
  exit 1
fi

echo "Creating and mounting logical volume on $TARGET_VOLUME"

if [[ -n "$(mount | grep -w "$TARGET_VOLUME")" ]]
then
  echo "$TARGET_VOLUME is already mounted. Skipping."
elif [[ -n "$(pvs --noheadings -o pv_name 2>/dev/null | grep -w "$TARGET_VOLUME")" ]]
then
  echo "$TARGET_VOLUME is already a physical volume. Skipping."
else
  echo "Creating physical volume"
  pvcreate "$TARGET_VOLUME"

  echo "Creating volume group"
  vgcreate ${ebs_vars["vg_name"]} "$TARGET_VOLUME"

  echo "Creating logical volume"
  lvcreate --name ${ebs_vars["lv_name"]} -l 100%FREE ${ebs_vars["vg_name"]}

  echo "Creating filesystem"
  mkfs.ext4 /dev/${ebs_vars["vg_name"]}/${ebs_vars["lv_name"]}

  echo "Adding entry to fstab and mounting ${ebs_vars["mount_point"]}"
  mkdir -p ${ebs_vars["mount_point"]}
  echo "/dev/${ebs_vars["vg_name"]}/${ebs_vars["lv_name"]} ${ebs_vars["mount_point"]} ext4 defaults 0 0" >> /etc/fstab

  echo "Copy initial data to newly created ${ebs_vars["mount_point"]} filesystem"
  mount /dev/${ebs_vars["vg_name"]}/${ebs_vars["lv_name"]} /mnt
  rsync -a ${ebs_vars["mount_point"]}/ /mnt/
  umount /mnt

  echo "Mount filesystem"
  mount ${ebs_vars["mount_point"]}
fi

if [[ -n "$(pvs 2>/dev/null | grep ${ebs_vars["vg_name"]})" ]] && [[ -z "$(mount | grep ${ebs_vars["lv_name"]})" ]]
then
  echo "${ebs_vars["lv_name"]} found but is not mounted ... mounting"
  if [[ -z "$(grep ${ebs_vars["lv_name"]} /etc/fstab)" ]]
  then
    mkdir -p ${ebs_vars["mount_point"]}
    echo "/dev/${ebs_vars["vg_name"]}/${ebs_vars["lv_name"]} ${ebs_vars["mount_point"]} ext4 defaults 0 0" >> /etc/fstab
  fi
  mount ${ebs_vars["mount_point"]}
fi

# EFS
if [ "${efs_mount_point}" != "N/A" ]; then
  echo "Adding entry to fstab and mounting ${efs_mount_point}"
  mkdir -p ${efs_mount_point}
  echo "${efs_share}:/ ${efs_mount_point} nfs ${efs_mount_options} 0 0" >> /etc/fstab
  mount ${efs_mount_point}
fi
