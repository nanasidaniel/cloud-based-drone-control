#!/bin/bash

if [[ ! -z $1]] && [[ $1 == 'kill' ]]; then
    docker rm $(docker ps -a -q -f name=drone)
fi

cd "$(dirname "$0")"
source config.sh
source docker-credentials.sh

service_dir=$(pwd)
cd ${service_dir}/..
work_dir=$(pwd)
cd $service_dir
drone_control_dir=${work_dir}/${drone_control_dir_name}

echo "DEPLOY DRONES"
MASTER_IP=$(multipass list | grep $master | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
for i in $(seq 1 ${NUMBER_OF_DRONES}); do

    echo 
    echo "DRONE-"$i
    echo "-------------------------------------------------"

    DASHBOARD_PORT=$((i-1+DASHBOARD_START_PORT))
    MAVLINK_PORT=$((i-1+MAVLINK_START_PORT))
    FCU_PORT=$((i-1+FCU_START_PORT))

    docker run -d nanasidnl/drone_control:px4sim \
        --name drone-$i \
        --env ROS_MASTER_URI=http//${MASTER_IP}:${FCU_PORT} \
        --port ${DASHBOARD_START_PORT}:1000 \
        --port ${FCU_PORT}:14580

    sleep 10
done

echo
echo "PODS LIST: "
multipass exec ${master} -- kubectl get pods -o wide
