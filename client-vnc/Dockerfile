ARG DOCKER_REGISTRY_URL=localhost:5000
ARG BASE_IMAGE=onec-client
ARG BASE_TAG=8.3.25.1546
FROM ${DOCKER_REGISTRY_URL}/${BASE_IMAGE}:${BASE_TAG}

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64-installer /tmp/s6-overlay-installer
COPY ./client-vnc/1cestart.desktop /root/Desktop/1cestart.desktop
USER root

RUN apt-get update \
    && env DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        at-spi2-core \
        dbus-x11 \
        dirmngr \
        git \
        gnupg \
        iproute2 \
        procps \
        psmisc \
        x11-utils \
        x11-xserver-utils \
        x11vnc \
        xdg-utils \
        xfce4 \
        xfce4-goodies \
        xubuntu-icon-theme \
    && rm -rf /var/lib/apt/lists/* /var/cache/debconf \
    && mkdir -p /root/.gnupg && chmod 700 /root/.gnupg \
    && chmod +x /root/Desktop/1cestart.desktop \
    && chmod +x /tmp/s6-overlay-installer && /tmp/s6-overlay-installer /

COPY ./configs/client-vnc/rootfs/ /

EXPOSE 5900

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru 
ENV LC_ALL=ru_RU.UTF-8
ENV DISPLAY=:1
ENV DISPLAY_WIDTH=1440
ENV DISPLAY_HEIGHT=900

ENTRYPOINT ["/init"]
