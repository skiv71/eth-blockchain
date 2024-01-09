#!/bin/bash

JWT_SECRET="jwtsecret.hex"
JAVA_HOME=/usr/lib/jvm/default-java/

export JAVA_HOME=$JAVA_HOME

ERROR() {
    echo $@
    exit 1
}

SECRET() {
    echo "Generating secret: $1"
    openssl rand -hex 32 | tr -d "\n" > $1
}

BIN() {
    local bin=$WORK_DIR/$1/bin/$1
    [[ -f $bin ]] || ERROR Unable to find $bin!
    [[ -x $bin ]] || ERROR $bin is not an executable!
    echo $bin
}

BESU() {
    local bin=`BIN besu`
    echo "Starting BESU..."
    $bin \
        --network=goerli            \
        --rpc-http-enabled=true     \
        --rpc-http-host=0.0.0.0     \
        --rpc-http-cors-origins="*" \
        --rpc-ws-enabled=true       \
        --rpc-ws-host=0.0.0.0       \
        --host-allowlist="*"        \
        --engine-host-allowlist="*" \
        --engine-rpc-enabled        \
        --engine-jwt-secret=$1 &
    while ! netcat -z localhost 8545; do
        sleep 1
    done
}

TEKU() {
    local bin=`BIN teku`
    echo "Starting TEKU..."
    $bin \
    --network=goerli \
    --ee-endpoint=http://localhost:8551 \
    --ee-jwt-secret-file=$1 \
    --metrics-enabled=true \
    --rest-api-enabled=true \
    --ignore-weak-subjectivity-period-enabled
}

MAIN() {
    case $1 in
        "goerli")
            BESU $JWT_SECRET
            TEKU $JWT_SECRET
            ;;
        *)
            ERROR "Invalid ETH_NETWORK: $1!"
            ;;
    esac
}


[[ -n $WORK_DIR ]] && echo "Using WORK_DIR: ${WORK_DIR}" || ERROR Invalid WORK_DIR ENV!

JWT_SECRET=$WORKDIR/$JWT_SECRET

[[ -f $JWT_SECRET ]] || SECRET $JWT_SECRET

MAIN $ETH_NETWORK $JWT_SECRET
