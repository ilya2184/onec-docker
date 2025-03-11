# Используем базовый образ для скачивания
ARG DOCKER_REGISTRY_URL=localhost:5000
ARG BASE_IMAGE=oscript-downloader
ARG BASE_TAG=latest

FROM ${DOCKER_REGISTRY_URL}/${BASE_IMAGE}:${BASE_TAG} AS downloader

# Копирование скрипта скачивания и локальных дистрибутивов
COPY ./scripts/download_yard.sh /download.sh
RUN chmod +x /download.sh

# Скачивание дистрибутива 1С с использованием вынесенного скрипта
WORKDIR /tmp

# Установка необходимых пакетов и генерация локали
RUN apt-get update \
  && apt-get install --yes \
    locales \
    p7zip-full \
    p7zip-rar \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen ru_RU.UTF-8 \
  && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8

# Установка переменных окружения для корректной работы локали
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

ENTRYPOINT ["/download.sh"]
CMD ["0000000", "-", "8.3.25.1546", "server"]

VOLUME /tmp/downloads