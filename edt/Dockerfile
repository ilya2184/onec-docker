ARG BASE_IMAGE=bellsoft/liberica-openjdk-debian
ARG BASE_TAG=17.0.14

FROM ${BASE_IMAGE}:${BASE_TAG}
ARG DISTR_VERSION=2024.2.3
ARG DISTR_HOST=host.docker.internal:5555

ADD https://download2.gluonhq.com/openjfx/17.0.14/openjfx-17.0.14_linux-x64_bin-sdk.zip /tmp/javafx-sdk.zip

WORKDIR /tmp

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes \
    libgtk-3-0 \
    locales \
    unzip \
    wget \
  && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* \
  && unzip /tmp/javafx-sdk.zip -d /opt/ \
  && rm /tmp/javafx-sdk.zip \
  # /usr/lib/jvm - для либерики, зулу 17, /opt/java/openjdk - для eclipse-temurin 11
  && JAVA_LIBS=$(find /usr/lib/jvm /opt/java/openjdk -name "lib" -type d | head -n 1) \
  && cp /opt/javafx-sdk-17.0.14/lib/* "$JAVA_LIBS" \
  && localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
  && export LANG=ru_RU.UTF-8 && export LANGUAGE=ru_RU:ru && export LC_ALL=ru_RU.UTF-8 \
  && wget --recursive --no-parent --quiet \
      http://${DISTR_HOST}/distr/DevelopmentTools10/${DISTR_VERSION} \
  && mv /tmp/${DISTR_HOST}/distr/DevelopmentTools10/${DISTR_VERSION}/* /tmp/ \
  && chmod +x ./1ce-installer-cli \
  && ./1ce-installer-cli install all --ignore-hardware-checks --ignore-signature-warnings \
  && rm -rf /tmp/* \
  && mv $(dirname $(find /opt/1C/1CE -name ring)) /opt/1C/1CE/components/1c-enterprise-ring \
  #1cedtcli отсутствует в EDT версии <2023.1.0
  && { if [ -n "$(find /opt/1C/1CE -name 1cedtcli)" ]; then \
      mv $(dirname $(find /opt/1C/1CE -name 1cedtcli)) /opt/1C/1CE/components/1cedtcli; \
    fi }

ENV PATH="/opt/1C/1CE/components/1c-enterprise-ring:/opt/1C/1CE/components/1cedtcli:$PATH"

WORKDIR /tmp