FROM ubuntu

RUN set -eux \
  ; apt-get update \
  ; apt-get install -y --no-install-recommends curl zstd git \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
