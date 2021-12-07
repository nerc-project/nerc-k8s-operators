#!/bin/bash

INTERFACE=${INTERFACE:-bond0.2142}

function label_node() {
  set -x
  oc label $1 ipfailover=public-vip
  set +x
}

for node in $(oc get nodes -o name); do
  oc debug --as-root $node -- chroot /host ip addr show "${INTERFACE}" &>/dev/null
  if [ "$?" == "0" ];
  then
    label_node $node
  else
    echo "!! Network interface ${INTERFACE} not found on node ${node}" 1>&2
    continue
  fi
done
