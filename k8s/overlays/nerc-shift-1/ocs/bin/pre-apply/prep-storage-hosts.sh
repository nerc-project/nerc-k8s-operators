#!/bin/bash

COUNTDOWN=${COUNTDOWN:-5}
CEPH_DISK=${CEPH_DISK:-null}

function confirm() {
  echo "!!! About to wipe data on ${1}:${CEPH_DISK} and add ${1} to OCS"
  echo "!!! Are you 100% sure you wish to proceed?"
  echo "!!! Please type ${1} and press ENTER to confirm"
  echo

  read USER_CODE

  if [ "${1}" != "$USER_CODE" ]; then
    echo "Input does not match the confirm code" 1>&2
    exit 1
  fi
}

function countdown() {
  echo
  echo "!!! Proceeding in ${COUNTDOWN} seconds... (ctl-c to abort)"
  echo

  for i in $(seq $COUNTDOWN -1 1); do
    printf "${i}..." && sleep 1
  done

  echo
}

function wipe_disks() {
  oc debug --as-root=true "node/${1}" -- <<EOF
set -x
chroot /host wipefs -a ${CEPH_DISK}
chroot /host sgdisk --zap ${CEPH_DISK}
chroot /host dd if=/dev/zero of=${CEPH_DISK} bs=1M count=10 conv=fsync
EOF
}

function enable_ocs_host() {
  oc patch node "${1}" -p '{"metadata": {"labels": {"cluster.ocs.openshift.io/openshift-storage": ""}}}'
}

if [ "${CEPH_DISK}" == 'null' ];
then
  echo "!!! Missing ceph data disk configuration" 1>&2
  echo "!!! Please set the CEPH_DISK environment variable (e.g. CEPH_DISK=/dev/sdb)"1>&2
  exit 1
fi

for node in $(oc get nodes -o name | sed 's:^node/::g'); do
  confirm $node
  countdown $node
  wipe_disks $node
  enable_ocs_host $node
done
