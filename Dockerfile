FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV DATA_DIR=/data/hyperledger
ENV ETH_NETWORK=goerli

ARG APT_DEPS="wget ca-certificates net-tools netcat-traditional unzip libjemalloc-dev"
ARG APP_DIR=/opt/hyperledger

ARG JDK_URL="https://github.com/ibmruntimes/semeru17-binaries/releases/download/jdk-17.0.9%2B9_openj9-0.41.0/ibm-semeru-open-jdk_x64_linux_17.0.9_9_openj9-0.41.0.tar.gz"
ARG TEKU_URL="https://artifacts.consensys.net/public/teku/raw/names/teku.zip/versions/23.12.1/teku-23.12.1.zip"
ARG BESU_URL="https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/23.10.3/besu-23.10.3.zip"

ARG BIN=/usr/local/bin
ARG WORK_DIR=/opt/docker

SHELL ["/bin/bash", "-c"]

RUN apt-get update >/dev/null && \
    apt-get install -y --no-install-recommends ${APT_DEPS} &>/dev/null && \
    apt-get clean

WORKDIR ${APP_DIR}

WORKDIR /tmp

RUN wget ${BESU_URL} \
    && wget ${TEKU_URL} \
    && wget ${JDK_URL}

RUN tar -xvf ibm*.gz -C ${APP_DIR} \
    && ln -s ${APP_DIR}/jdk*/bin/java ${BIN}/java

RUN unzip besu*.zip -d ${APP_DIR} \
    && ln -s ${APP_DIR}/besu*/bin/besu ${BIN}/besu

RUN unzip teku*.zip -d ${APP_DIR} \
    && ln -s ${APP_DIR}/teku*/bin/teku ${BIN}/teku

WORKDIR ${WORK_DIR}

COPY . .

RUN chmod +x *.sh

EXPOSE 8545
EXPOSE 30303
EXPOSE 30303/udp

ENTRYPOINT [ "./entrypoint.sh" ]
