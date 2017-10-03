#!/bin/bash
CLUSTERNAME=$1
NUMBEROFNODES=$2
MEMTOTAL=$(($3*1000000))

source props
echo $disks_folder/$CLUSTERNAME:/disks


if [ -d "$disks_folder/$CLUSTERNAME" ]; then
 echo "Folder $disks_folder/$CLUSTERNAME exists, skipping disks creation"
else
 echo "Starting to create disks"
 	 mkdir $disks_folder/$CLUSTERNAME
 	./mkdisks.sh $NUMBEROFNODES 15 $disks_folder/$CLUSTERNAME
fi

master_cid=$(docker run --entrypoint /bin/bash -dti --privileged --name ${CLUSTERNAME}-master -h ${CLUSTERNAME}-master  -e "CLUSTERNAME=${CLUSTERNAME}" -e "DISKLIST=/disks/disk0" -e "MEMTOTAL=${MEMTOTAL}" -v $disks_folder/$CLUSTERNAME:/disks $master_image)
sleep 10
master_ip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${master_cid} )
container_ips[0]=$master_ip
echo "Control Node IP : $master_ip		Starting the cluster: https://${master_ip}:8443/    login:mapr   password:mapr"
hosts_file=/tmp/hosts.$$
echo -e "$master_ip\t${CLUSTERNAME}-master.mapr.io\t${CLUSTERNAME}-master" > $hosts_file

docker exec -d ${CLUSTERNAME}-master /bin/sh -c /usr/bin/init-script
sleep 30

i=1
while [[ $i -lt $NUMBEROFNODES ]]
do
  data_cid=$(docker run --entrypoint /bin/bash -dti --privileged --name ${CLUSTERNAME}-slave${i} -h ${CLUSTERNAME}-slave${i} -e "CLDBIP=${master_ip}" -e "DISKLIST=/disks/disk$i" -e "CLUSTERNAME=${CLUSTERNAME}" -e "MEMTOTAL=${MEMTOTAL}" -v $disks_folder/$CLUSTERNAME:/disks $slave_image)
  sleep 10
  dip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${data_cid} )
  container_ips[$i]=$dip
  echo -e "$dip\t${CLUSTERNAME}-slave${i}.mapr.io\t${CLUSTERNAME}-slave${i}" >> $hosts_file
  docker exec -d ${CLUSTERNAME}-slave${i} /bin/sh -c /usr/bin/init-script
  i=`expr $i + 1`
done

cat /tmp/hosts.$$


for ip in "${container_ips[@]}"
 do
 	echo $ip

sshpass -p "mapr" scp -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r $hosts_file root@${ip}:/tmp/hosts
sshpass -p "mapr" ssh -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} 'cat /tmp/hosts >> /etc/hosts'
sshpass -p "mapr" scp -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ./$drill root@${ip}:/root
#sshpass -p "mapr" scp -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ./mysql-connector-java-5.1.17-bin.jar root@${ip}:/root
sshpass -p "mapr" scp -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ./startup.sh root@${ip}:/root
sshpass -p "mapr" ssh -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${ip} "tar -xf /root/$drill"

 done

echo "cluster_name=${CLUSTERNAME}" > meta
echo "nodes_count=${NUMBEROFNODES}" >> meta
