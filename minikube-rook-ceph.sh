#!/bin/bash

rook_version=$1
minikube=$(which minikube)
git=$(which git)
vboxmanage=$(which vboxmanage)
kubectl=$(which kubectl)
work_dir=$(pwd)

vm_name="rook-ceph"
ceph_disk="$HOME/.minikube/machines/$vm_name/ceph-disk"

usage() {
    if [[ -z $rook_version ]]; then
        echo ""
        echo "Usage: $0 [rook_version]"
        echo "Example: $0 1.0"
        exit 1
    fi
}

usage

$minikube start -p $vm_name --cpus 2 --memory 2048
$minikube -p $vm_name status

$vboxmanage createmedium disk --filename $ceph_disk --size 8192 --format VDI --variant Standard
$vboxmanage storageattach $vm_name \
                         --storagectl "SATA" \
                         --device 0 \
                         --port 2 \
                         --type hdd \
                         --medium "$ceph_disk.vdi"


$git clone https://github.com/rook/rook.git 
cd $work_dir/rook && \
$git fetch && \
$git checkout "release-$rook_version" && \
cd $work_dir/rook/cluster/examples/kubernetes/ceph

$minikube -p $vm_name update-context
$kubectl create ns rook-ceph
$kubectl -n rook-ceph create -f common.yaml
$kubectl -n rook-ceph create -f operator.yaml

sed -i 's!/var/lib/rook!/data/rook-dir!g' cluster-test.yaml

$kubectl -n rook-ceph create -f cluster-test.yaml

echo "Ceph deplyoment in progress..."
watch $kubectl -n rook-ceph get all
