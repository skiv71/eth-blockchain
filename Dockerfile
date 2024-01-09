FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV WORK_DIR=/opt/hyperledger
ENV ETH_NETWORK=goerli

ARG DEPS="wget ca-certificates net-tools netcat-traditional default-jdk unzip libjemalloc-dev"
ARG TMP="/tmp"
ARG WORKING=${WORK_DIR}
ARG TEKU="https://artifacts.consensys.net/public/teku/raw/names/teku.zip/versions/23.12.1/teku-23.12.1.zip"
ARG BESU="https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/23.10.3/besu-23.10.3.zip"

SHELL ["/bin/bash", "-c"]

WORKDIR ${WORKING}

WORKDIR ${TMP}

RUN apt-get update >/dev/null && \
    apt-get install -y --no-install-recommends ${DEPS} &>/dev/null && \
    apt-get clean

RUN wget ${BESU} \
    && unzip *.zip -d ${WORKING} \
    && ln -s ${WORKING}/besu* ${WORKING}/besu \
    && rm -rf *.zip

RUN wget ${TEKU} \
    && unzip *.zip -d ${WORKING} \
    && ln -s ${WORKING}/teku* ${WORKING}/teku \
    && rm -rf *.zip

WORKDIR ${WORKING}

COPY . .

RUN chmod +x *.sh

EXPOSE 8545
EXPOSE 30303
EXPOSE 30303/udp

ENTRYPOINT [ "./entrypoint.sh" ]
