#!/bin/bash


cd "$(dirname "$0")"
source ../config/configUp.sh
source ../config/docker-credentials.sh

if [ ! -z $1 ] && [ $1 == 'kill' ]; then
    for i in $(seq 1 $NUMBER_OF_DRONES); do
        multipass exec ${master} -- sudo kubectl delete -f ${service_dir}/kube-roscore-$i.yml
        rm ${service_dir}/kube-roscore-$i.yml
        multipass exec $master -- kubectl delete -f ${service_dir}/kube-drone-hq-$i.yml
        rm ${service_dir}/kube-drone-hq-$i.yml
    done
    exit
fi

echo "MOUNT WORKING DIRECTORY"
multipass mount ${work_dir} ${master}

multipass exec $master -- kubectl label nodes ${ROSCORE_NODE} dedicated=roscore

MASTER_IP=$(multipass list | grep $master | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
ROSCORE_IP=$(multipass list | grep $ROSCORE_NODE | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

echo
echo "DEPLOY ROSCORES ON KUBERNETES"
for i in $(seq 1 ${NUMBER_OF_DRONES}); do

    MAVLINK_PORT=$((i-1+MAVLINK_START_PORT))

    echo 
    echo "ROSCORE-"$i
    echo "-------------------------------------------------"
    cp ${service_dir}/kube-roscore.yml ${service_dir}/kube-roscore-$i.yml
    sed -i 's/$(MAVLINK_PORT)/'${MAVLINK_PORT}'/g' ${service_dir}/kube-roscore-$i.yml
    sed -i 's/$(DRONE_IDENTIFIER)/'${i}'/g' ${service_dir}/kube-roscore-$i.yml
    multipass exec ${master} -- sudo kubectl apply -f ${service_dir}/kube-roscore-$i.yml
done

echo
echo "PODS LIST: "
multipass exec ${master} -- kubectl get pods -o wide

