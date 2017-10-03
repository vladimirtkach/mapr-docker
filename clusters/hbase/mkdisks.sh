#!/bin/bash

disk_count=$1
disk_size=$2
location=$3

for i in $(seq 0 `expr $disk_count - 1`)
do
	echo "Creating disk: disk$i"
 	dd if=/dev/zero of=$location/disk$i bs=1G count=$disk_size
 	
done
