#!/bin/bash

JWT_FILE="jwtsecret.hex"
JAVA_HOME=/usr/lib/jvm/default-java/

export JAVA_HOME=$JAVA_HOME

ERROR() {
    echo $1
    exit 1
}

SECRET() {
    echo "Generating secret: $1"
    openssl rand -hex 32 | tr -d "\n" > $1
}

BESU() {
    echo "Starting BESU, network: $1, data: $2"
    besu \
        --network=$1 \
        --rpc-http-enabled=true \
        --rpc-http-host=0.0.0.0 \
        --rpc-http-cors-origins="*" \
        --rpc-ws-enabled=true \
        --rpc-ws-host=0.0.0.0 \
        --host-allowlist="*" \
        --engine-host-allowlist="*" \
        --engine-rpc-enabled \
        --data-path=$2 \
        --engine-jwt-secret=$3 &
    while ! netcat -z localhost 8545; do
        sleep 1
    done
}

TEKU() {
    echo "Starting TEKU, network: $1, data: $2"
    teku \
    --network=$1 \
    --ee-endpoint=http://localhost:8551 \
    --data-base-path=$2 \
    --ee-jwt-secret-file=$3 \
    --metrics-enabled=true \
    --rest-api-enabled=true \
    --ignore-weak-subjectivity-period-enabled
}

MKDIR() {
    echo "Creating $1..."
    mkdir -p $1
}

MAIN() {
    case $1 in
        "goerli")
            BESU $1 $2/besu $3
            TEKU $1 $2/teku $3
            ;;
        *)
            ERROR "Invalid ETH_NETWORK: $1!"
            ;;
    esac
}

[[ -n $DATA_DIR ]] || ERROR "Empty DATA_DIR ENV!"

[[ -d $DATA_DIR ]] && echo "Using DATA_DIR: $DATA_DIR..." || MKDIR $DATA_DIR 

JWT_PATH=$DATA_DIR/$JWT_FILE

[[ -f $JWT_PATH ]] || SECRET $JWT_PATH

MAIN $ETH_NETWORK $DATA_DIR $JWT_PATH
