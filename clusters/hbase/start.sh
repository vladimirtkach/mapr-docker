#!/bin/bash

source meta

docker start ${cluster_name}-master
docker exec -d ${cluster_name}-master /bin/sh -c /root/startup.sh


i=1
while [[ $i -lt $nodes_count ]]
do   
	docker start ${cluster_name}-slave$i
	docker exec -d ${cluster_name}-slave$i /bin/sh -c /root/startup.sh
 i=`expr $i + 1`
done

