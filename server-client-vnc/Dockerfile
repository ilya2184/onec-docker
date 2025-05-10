ARG BASE_IMAGE=ubuntu
ARG BASE_TAG=20.04

FROM ${BASE_IMAGE}:${BASE_TAG}

ARG DISTR_HOST=host.docker.internal:8088
ARG DISTR_VERSION=8.3.27.1508

WORKDIR /tmp

ADD https://github.com/tianon/gosu/releases/download/1.17/gosu-amd64 /bin/gosu
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64-installer /tmp/s6-overlay-installer
COPY ./server/logcfg-excp.xml /tmp/logcfg-excp.xml
COPY ./client-vnc/1cestart.desktop /tmp/1cestart.desktop

RUN set -xe \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        at-spi2-core \
        ca-certificates \
        dbus-x11 \
        dirmngr \
        fontconfig \
        git \
        gnupg \
        imagemagick \
        iproute2 \
        libfontconfig1 \
        libglib2.0-0 \
        libglu1-mesa \
        libgsf-1-114 \
        libgssapi-krb5-2 \
        libgtk2.0-0 \
        libmagickwand-6.q16-6 \
        libodbc1 \
        libsm6 \
        libwebkit2gtk-4.0-37 \
        locales \
        procps \
        psmisc \
        socat \
        ttf-mscorefonts-installer \
        tzdata \
        wget \
        x11-utils \
        x11-xserver-utils \
        x11vnc \
        xdg-utils \
        xfce4 \
        xfce4-goodies \
        xubuntu-icon-theme \
        xvfb \
    # общая настройка
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* /var/cache/debconf \
    && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
    # Загрузка и установка 1С
    && wget --recursive --no-parent --quiet \
        http://${DISTR_HOST}/distr/Platform83/${DISTR_VERSION} \
    && mv /tmp/${DISTR_HOST}/distr/Platform83/${DISTR_VERSION}/* /tmp/ \
    && RUN_FILE=$(find /tmp -name "*.run" | head -n 1) \
    && chmod +x ${RUN_FILE} \
    && ${RUN_FILE} --mode unattended --enable-components "server,ws,config_storage_server,client_full,client_thin,client_thin_fib,liberica_jre,ru" \
    # настраиваем текущую директорию
    && PLATFORM_PATH=$( \
        find / -type f -name "1cv8c" -exec dirname {} \; -or \
        -type f -name "1cv8" -exec dirname {} \; | uniq ) \
    && mkdir -p /opt/1cv8 \
    && ln -s ${PLATFORM_PATH} /opt/1cv8/current \
    # gosu
    && chmod +x /bin/gosu \
    # прользователь и группа для работы 1С
    && getent group grp1cv8 || groupadd -r grp1cv8 --gid=999 \
    && getent passwd usr1cv8 || useradd -r -g grp1cv8 --uid=999 --home-dir=/home/usr1cv8 --shell=/bin/bash usr1cv8 \
    && mkdir -p /var/log/1C /home/usr1cv8/.1cv8/1C/1cv8/conf /opt/1cv8/current/conf /var/1C/licenses \
    # кладем конфиг сервера
    && cp /tmp/logcfg-excp.xml /opt/1cv8/current/conf \
    && ln -s /opt/1cv8/current/conf/logcfg-excp.xml /opt/1cv8/current/conf/logcfg.xml \
    # обход ошибки некоторых версий 1С
    && ln -s /tmp /opt/1cv8/common/tmp \
    # точка входа
    && mkdir -p /home/usr1cv8/.gnupg && chmod 700 /home/usr1cv8/.gnupg \
    && chmod +x /tmp/s6-overlay-installer && /tmp/s6-overlay-installer / \
    # ярлык для 1С
    && mkdir /home/usr1cv8/Desktop \
    && cp /tmp/1cestart.desktop /home/usr1cv8/Desktop/1cestart.desktop \
    && chmod +x /home/usr1cv8/Desktop/1cestart.desktop \
    && chown -R usr1cv8:grp1cv8 /var/log/1C /home/usr1cv8 /opt/1cv8/current/conf /var/1C/licenses \
    # зачищаем временные файлы
    && rm -rf /tmp/*

COPY ./configs/client-vnc/rootfs/ /

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru 
ENV LC_ALL=ru_RU.UTF-8
ENV PATH="/opt/1cv8/current:/opt/1cv8/common:$PATH"
ENV HOME=/home/usr1cv8
ENV DISPLAY=:0
ENV DISPLAY_WIDTH=1440
ENV DISPLAY_HEIGHT=900

# не используй mount bind, только volume bind
VOLUME /home/usr1cv8/.1cv8 /var/log/1C /var/1C/licenses

EXPOSE 1540 1541 1545 1560 1561 8413

ENTRYPOINT ["/init"]
