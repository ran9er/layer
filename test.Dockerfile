FROM fj0rd/0x:or

RUN set -eux \
  ; curl layer.xinminghui.com/setup.sh | sh -s china \
  ; apk add --no-cache python3 py3-yaml
