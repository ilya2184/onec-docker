ARG BASE_IMAGE=ubuntu
ARG BASE_TAG=20.04

FROM ${BASE_IMAGE}:${BASE_TAG}

ARG DISTR_HOST=host.docker.internal:8088
ARG DISTR_VERSION=8.3.25.1546

WORKDIR /tmp

ADD https://github.com/tianon/gosu/releases/download/1.17/gosu-amd64 /bin/gosu
COPY ./client/docker-entrypoint.sh /tmp/docker-entrypoint.sh
COPY ./client/conf.cfg /tmp/conf.cfg

RUN set -xe \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
      ca-certificates \
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
      ttf-mscorefonts-installer \
      tzdata \
      wget \
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
    && ${RUN_FILE} --mode unattended --enable-components "client_full,client_thin,client_thin_fib,ru" \
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
    && mkdir -p /var/log/1C /home/usr1cv8/.1cv8/1C/1cv8/conf /opt/1cv8/current/conf \
    && chown -R usr1cv8:grp1cv8 /var/log/1C /home/usr1cv8 \
    # кладем конфиг клиента
    && cp /tmp/conf.cfg /opt/1cv8/current/conf \
    # обход ошибки некоторых версий 1С
    && ln -s /tmp /opt/1cv8/common/tmp \
    # чтобы xvfb нормально работал
    && mkdir -p /tmp/.X11-unix \
    && chmod 1777 -R /tmp \
    # точка входа
    && cp /tmp/docker-entrypoint.sh / \
    && chmod +x /docker-entrypoint.sh \
    # зачищаем временные файлы
    && rm -rf /tmp/*

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru 
ENV LC_ALL=ru_RU.UTF-8
ENV PATH="/opt/1cv8/current:/opt/1cv8/common:$PATH"
ENV DISPLAY=:0
ENV DISPLAY_WIDTH=1440
ENV DISPLAY_HEIGHT=900

# не используй mount bind, только volume bind
VOLUME /home/usr1cv8

# порты менеджера тестирования
EXPOSE 1538 1539

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["1cv8"]
