#!/bin/bash

JWT_FILE="jwtsecret.hex"
JAVA_HOME=

ERROR() {
    echo $1
    exit 1
}

SECRET() {
    echo "Generating secret: $1"
    openssl rand -hex 32 | tr -d "\n" > $1
}

TEKU() {
    echo "Starting TEKU, network: $1, data: $2, secret: $3, checkpoint: $4"
    teku \
    --network=$1 \
    --ee-endpoint=http://localhost:8551 \
    --data-base-path=$2 \
    --ee-jwt-secret-file=$3 \
    --checkpoint-sync-url=$4 \
    --metrics-enabled=true
}

NETHERMIND() {
    local snap=`SNAP_SYNC $1`
    echo "Starting NETHERMIND, network: $1, data: $2, secret: $3, snap: $snap"
    nethermind \
        --config $1 \
        --datadir $2 \
        --HealthChecks.Enabled true \
        --JsonRpc.Host "0.0.0.0" \
        --Sync.SnapSync $sync \
        --JsonRpc.JwtSecretFile $3 &
}

MKDIR() {
    echo "Creating $1..."
    mkdir -p $1
}

CHECKPOINT_URL() {
    case $1 in
        "goerli")
            echo "https://beaconstate-goerli.chainsafe.io/"
            ;;
        "sepolia")
            echo "https://beaconstate-sepolia.chainsafe.io/"
            ;;
        "gnosis")
            echo "https://checkpoint.gnosischain.com/"
            ;;
        *)
            ERROR "Invalid network: $1!"
            ;;
    esac
}

SNAP_SYNC() {
    case $1 in
        "goerli"|"sepolia")
            echo true
            ;;
        *)
            echo false
            ;;
    esac
}

MAIN() {
    local url=`CHECKPOINT_URL $1`
    local checkpoint=${ETH_CHECKPOINT:=$url}
    local rpc_timeout=${RPC_TIMEOUT:=300}
    echo "RPC_TIMEOUT: $rpc_timeout"
    NETHERMIND $1 $2/nethermind $3
    local n=0
    while ! netcat -z localhost 8545; do
        sleep 1
        ((n++))
        [[ $n -gt $RPC_TIMEOUT ]] && ERROR "RPC Server timeout!"
    done
    TEKU $1 $2/teku $3 $checkpoint
}

JAVA_HOME=`find / -type d -name jdk* 2> /dev/null | head -n 1`

[[ -n $JAVA_HOME ]] && echo "JAVA_HOME: $JAVA_HOME" || ERROR "Empty JAVA_HOME ENV!"

export JAVA_HOME=$JAVA_HOME

[[ -n $DATA_DIR ]] || ERROR "Empty DATA_DIR ENV!"

[[ -d $DATA_DIR ]] && echo "Using DATA_DIR: $DATA_DIR..." || MKDIR $DATA_DIR

JWT_PATH=$DATA_DIR/$JWT_FILE

[[ -f $JWT_PATH ]] || SECRET $JWT_PATH

MAIN $ETH_NETWORK $DATA_DIR $JWT_PATH
