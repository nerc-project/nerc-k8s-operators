#!/bin/bash

ROOT_PATH=./k8s

function run_kustomize() {
  echo -n "Running kustomize in ${1} ... "
  out=$(cd "${1}" && kustomize build 2>&1)
  if [ $? -ne 0 ]; then
    echo FAILED
    echo "${out}"
    exit 1
  else
    echo OK
  fi
}

for base in ${ROOT_PATH}/base/*; do
  run_kustomize "${base}"
done

for overlay in ${ROOT_PATH}/overlays/*; do
  run_kustomize "${overlay}"
done
