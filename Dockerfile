FROM debian:12-slim

# Runtime ENV
ENV DATA_DIR=/data
# (Required)
ENV ETH_NETWORK=
# (Optional)
ENV ETH_CHECKPOINT=
ENV RPC_TIMEOUT=

# Build ENV
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Start build
ARG APP_DIR=/opt
ARG BIN=/usr/local/bin
ARG WORK_DIR=/opt/docker

SHELL ["/bin/bash", "-c"]

# Create local directories
WORKDIR ${APP_DIR}
WORKDIR ${WORK_DIR}

COPY .resources/apt.txt .

# Install dependencies

RUN apt-get update >/dev/null && \
    apt-get install -y --no-install-recommends `cat apt.txt | tr "\n" " "` &>/dev/null && \
    apt-get clean

COPY .resources/wget.txt .

# Download runtimes
RUN wget -i wget.txt

# Extract runtimes
RUN tar -xvf ibm*.gz -C ${APP_DIR} \
    && ln -s ${APP_DIR}/jdk*/bin/java ${BIN}/java

RUN unzip teku*.zip -d ${APP_DIR} \
    && ln -s ${APP_DIR}/teku*/bin/teku ${BIN}/teku

RUN unzip nether*.zip -d ${APP_DIR}/Nethermind \
    && ln -s ${APP_DIR}/Nethermind/nethermind ${BIN}/nethermind

# Ports
EXPOSE 8545
EXPOSE 30303
EXPOSE 30303/udp

# Run build
WORKDIR ${WORK_DIR}

COPY ./entrypoint.sh .

RUN chmod +x *.sh

ENTRYPOINT [ "./entrypoint.sh" ]
