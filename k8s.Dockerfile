FROM ghcr.io/fj0r/0x:ci AS build
COPY k8s /opt/k8s

WORKDIR /opt/k8s
RUN set -eux \
  ; apt update \
  ; DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends wget \
  \
  ; mkdir -p /opt/pub \
  ; bash assets-update.sh \
  ; bash assets-download.sh \
  ; bash assets-k8s-download.sh \
  ;

FROM ghcr.io/fj0r/0x:or
COPY --from=build /opt/k8s /srv
