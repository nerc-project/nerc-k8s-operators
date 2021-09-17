#!/bin/bash

COUNTDOWN=5

function confirm() {
  echo "!!! About to wipe data on ${1}:/dev/sdb and add ${1} to OCS"
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
chroot /host wipefs -a /dev/sdb
chroot /host sgdisk --zap /dev/sdb
chroot /host dd if=/dev/zero of=/dev/sdb bs=1M count=10 conv=fsync
EOF
}

function enable_ocs_host() {
  oc patch node "${1}" -p '{"metadata": {"labels": {"cluster.ocs.openshift.io/openshift-storage": ""}}}'
}

for i in $(seq 0 2); do
  node="os-ctl-${i}"
  confirm $node
  countdown $node
  wipe_disks $node
  enable_ocs_host $node
done
