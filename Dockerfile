FROM debian:bookworm-slim AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG OSMO_TRACK=latest
ARG OSMO_DISTRO=Debian_12
ARG OSMO_KEY_URL=https://obs.osmocom.org/projects/osmocom/public_key
ARG OSMO_KEY_SHA256=cff40af0eab80e62f498825bf151c03f7a77ecaf5cf08b7e46cbc7b1b7a2e1bb

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    install -d -m 0755 \
        /usr/share/osmocom-keyring \
        /etc/apt/sources.list.d; \
    curl -fsSL "$OSMO_KEY_URL" -o /tmp/osmocom.asc; \
    echo "$OSMO_KEY_SHA256  /tmp/osmocom.asc" | sha256sum -c -; \
    install -m 0644 \
        /tmp/osmocom.asc \
        /usr/share/osmocom-keyring/osmocom.asc; \
    rm -f /tmp/osmocom.asc; \
    printf \
        'deb [signed-by=/usr/share/osmocom-keyring/osmocom.asc] https://downloads.osmocom.org/packages/osmocom:/%s/%s/ ./\n' \
        "$OSMO_TRACK" \
        "$OSMO_DISTRO" \
        > /etc/apt/sources.list.d/osmocom.list


# --------------------------------------------------
# HLR image
# --------------------------------------------------

FROM base AS hlr

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        osmo-hlr \
        sqlite3; \
    rm -rf /var/lib/apt/lists/*

RUN useradd -r -u 10001 -m -d /var/lib/osmocom osmo && \
    mkdir -p /var/lib/osmocom /etc/osmocom && \
    chown -R osmo:osmo /var/lib/osmocom /etc/osmocom

USER osmo
WORKDIR /var/lib/osmocom

COPY --chown=osmo:osmo osmo-hlr.cfg /etc/osmocom/osmo-hlr.cfg

# 4258 = HLR VTY, 4222 = HLR CTRL
EXPOSE 4258 4222

VOLUME ["/var/lib/osmocom"]

CMD ["osmo-hlr", "-c", "/etc/osmocom/osmo-hlr.cfg", "-l", "/var/lib/osmocom/hlr.db", "-e", "info"]


# --------------------------------------------------
# MSC image
# --------------------------------------------------

FROM base AS msc

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        osmo-msc; \
    rm -rf /var/lib/apt/lists/*

RUN useradd -r -u 10002 -m -d /var/lib/osmocom osmo && \
    mkdir -p /var/lib/osmocom /etc/osmocom && \
    chown -R osmo:osmo /var/lib/osmocom /etc/osmocom

USER osmo
WORKDIR /var/lib/osmocom

COPY --chown=osmo:osmo osmo-msc.cfg /etc/osmocom/osmo-msc.cfg

# 4254 = VTY, 4258 = HLR VTY, 29118 = MAP (SS7 user plane)
EXPOSE 4254 4258 29118

CMD ["osmo-msc", "-c", "/etc/osmocom/osmo-msc.cfg", "-e", "info"]

# --------------------------------------------------
# STP image
# --------------------------------------------------
FROM base AS stp
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        osmo-stp; \
    rm -rf /var/lib/apt/lists/*

RUN useradd -r -u 10003 -m -d /var/lib/osmocom osmo && \
    mkdir -p /var/lib/osmocom /etc/osmocom && \
    chown -R osmo:osmo /var/lib/osmocom /etc/osmocom

USER osmo
WORKDIR /var/lib/osmocom
COPY --chown=osmo:osmo osmo-stp.cfg /etc/osmocom/osmo-stp.cfg

# 4239 = VTY, 2905 = M3UA/SCTP (SS7 signalling plane)
EXPOSE 4239 2905

CMD ["osmo-stp", "-c", "/etc/osmocom/osmo-stp.cfg"]
