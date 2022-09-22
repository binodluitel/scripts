#!/usr/bin/env bash -e

# At least 1 param is require to run
if [ -z "$1" ]; then
    echo "Specify a function to run"
    echo "Example: ./db.sh start"
    exit 1
fi

# Check if docker and cockroachdb cli are installed
type docker >/dev/null 2>&1 || { echo 'docker is not installed.'; exit 1; }
type cockroach >/dev/null 2>&1 || { echo 'cockroach db cli is not installed.'; exit 1; }

PROJECT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
echo "Executing script in ${PROJECT_DIR}"

# Starts cockroach db in a docker containe in insecure mode
# for more info, visit: https://www.cockroachlabs.com/docs/stable/start-a-local-cluster-in-docker-mac.html
function config_roachdb() {
    echo "Starting Cockroach DB"
    docker network create -d bridge roach-db-net
    docker volume create roach-db-vol
    docker run -d \
        --name=roach-db \
        --hostname=roach-db-host \
        --net=roach-db-net \
        -p 26257:26257 -p 8080:8080  \
        -v "roach-db-vol:/cockroach/cockroach-data"  \
        cockroachdb/cockroach:v22.1.7 start \
        --insecure \
        --join=roach-db-host
    docker exec -it roach-db ./cockroach init --insecure

    # To print corkroach DB logs
    # docker exec -it roach-db grep 'node starting' cockroach-data/logs/cockroach.log -A 11

    # Exec into the container to run sql commands
    # docker exec -it roach-db ./cockroach sql --insecure

    # Create workload and workload_service users
    cockroach sql --host=localhost:26257 --insecure --execute="CREATE USER workload"
    cockroach sql --host=localhost:26257 --insecure --execute="CREATE USER workload_service"

    # Create workload and workload_test databases
    cockroach sql --host=localhost:26257 --insecure --execute="CREATE DATABASE workload_test"
    cockroach sql --host=localhost:26257 --insecure --execute="CREATE DATABASE workload"

    # Grant privileges to workload and workload_service users
    cockroach sql --host=localhost:26257 --insecure --execute="GRANT admin to workload"
    cockroach sql --host=localhost:26257 --insecure --execute="GRANT admin to workload_service"
}

function teardown_roachdb() {
    echo "Tearing down Cockroach DB"
    docker stop roach-db
    docker rm roach-db
    docker network rm roach-db-net
    docker volume rm roach-db-vol
}

function config_etcd() {
    echo "Starting Etcd"
}

function teardown_etcd() {
    echo "Tearing down Etcd"
}

function start() {
    config_roachdb
    config_etcd
}

function clean() {
    teardown_roachdb
    teardown_etcd
}

# run functions with params
${1} ${@:2}
