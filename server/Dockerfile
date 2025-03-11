ARG BASE_IMAGE=ubuntu
ARG BASE_TAG=20.04

FROM ${BASE_IMAGE}:${BASE_TAG}

ARG DISTR_HOST=host.docker.internal:8088
ARG ONEC_VERSION=8.3.25.1546

WORKDIR /tmp

ADD https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64 /bin/gosu
COPY ./server/logcfg.xml /tmp/logcfg.xml
COPY ./server/docker-entrypoint.sh /tmp/docker-entrypoint.sh

RUN set -xe \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        ca-certificates \
        libgssapi-krb5-2 \
        locales \
        procps \
        tzdata \
        wget \
    # общая настройка
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* /var/cache/debconf \
    && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
    # Загрузка и установка 1С
    && wget --recursive --no-parent --quiet \
        http://${DISTR_HOST}/distr/Platform83/${ONEC_VERSION} \
    && mv /tmp/${DISTR_HOST}/distr/Platform83/${ONEC_VERSION}/* /tmp/ \
    && RUN_FILE=$(find /tmp -name "*.run" | head -n 1) \
    && chmod +x ${RUN_FILE} \
    && ${RUN_FILE} --mode unattended --enable-components "server,ws,config_storage_server,liberica_jre,ru" \
    # настраиваем текущую директорию
    && PLATFORM_PATH=$( \
        find / -type f -name "ragent" -exec dirname {} \; -or \
        -type f -name "crserver" -exec dirname {} \; | uniq ) \
    && mkdir -p /opt/1cv8 \
    && ln -s ${PLATFORM_PATH} /opt/1cv8/current \
    # gosu
    && chmod +x /bin/gosu \
    # прользователь и группа для работы 1С
    && getent group grp1cv8 || groupadd -r grp1cv8 --gid=999 \
    && getent passwd usr1cv8 || useradd -r -g grp1cv8 --uid=999 --home-dir=/home/usr1cv8 --shell=/bin/bash usr1cv8 \
    && mkdir -p /var/log/1C /home/usr1cv8/.1cv8/1C/1cv8/conf /opt/1cv8/current/conf \
    && chown -R usr1cv8:grp1cv8 /var/log/1C /home/usr1cv8 \
    # кладем конфиг сервера
    && cp /tmp/logcfg.xml /opt/1cv8/current/conf \
    && ln -s /opt/1cv8/current/conflogcfg.xml /home/usr1cv8/.1cv8/1C/1cv8/conf/logcfg.xml \
    # точка входа
    && cp /tmp/docker-entrypoint.sh / \
    && chmod +x /docker-entrypoint.sh \
    # зачищаем временные файлы
    && rm -rf /tmp/*

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru 
ENV LC_ALL=ru_RU.UTF-8
ENV PATH="/opt/1cv8/current:$PATH"

VOLUME /home/usr1cv8/.1cv8 /var/log/1C

ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 1540 1541 1545 1560
CMD ["ragent"]
