FROM debian:stable-slim as builder

WORKDIR /data

RUN apt-get update -qq && apt-get -y install --no-install-recommends \
        ca-certificates \
        build-essential \
        git \
        curl

ARG BINARIES_URL
ARG ACCESS_TOKEN

RUN curl --header "PRIVATE-TOKEN: $ACCESS_TOKEN" $BINARIES_URL/monero-wallet-cli --output /data/monero-wallet-cli \
    && curl --header "PRIVATE-TOKEN: $ACCESS_TOKEN" $BINARIES_URL/monero-wallet-rpc --output /data/monero-wallet-rpc \
    && curl --header "PRIVATE-TOKEN: $ACCESS_TOKEN" $BINARIES_URL/monerod --output /data/monerod \
    && chmod 755 /data/monerod \
    && chmod 755 /data/monero-wallet-cli \
    && chmod 755 /data/monero-wallet-rpc

RUN cd /data \
    && git clone https://github.com/ncopa/su-exec.git su-exec-clone \
    && cd su-exec-clone \
    && make \
    && cp su-exec /data

RUN apt-get purge -y \
        ca-certificates \
        build-essential \
        git \
        curl \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && rm -rf /var/tmp/* /tmp/* /var/lib/apt \
    && rm -rf /data/su-exec-clone

FROM debian:stable-slim
COPY --from=builder /data/monerod /usr/local/bin/
COPY --from=builder /data/monero-wallet-rpc /usr/local/bin/
COPY --from=builder /data/monero-wallet-cli /usr/local/bin/
COPY --from=builder /data/su-exec /usr/local/bin/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /monero
VOLUME ["/monero"]

ENV USER_ID 1000
ENV LOG_LEVEL 0
ENV DAEMON_HOST 127.0.0.1
ENV DAEMON_PORT 28081
ENV RPC_BIND_IP 0.0.0.0
ENV RPC_BIND_PORT 28081
ENV P2P_BIND_IP 0.0.0.0
ENV P2P_BIND_PORT 28080

ENTRYPOINT ["/entrypoint.sh"]
