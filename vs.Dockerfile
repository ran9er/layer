FROM fj0rd/io:base as build
ENV commit_id='6261075646f055b99068d3688932416f2346dd3b'
RUN set -eux \
  ; mkdir -p /target /tmp/.vscode-server/bin/${commit_id} \
  ; curl -sSL "https://update.code.visualstudio.com/commit:${commit_id}/server-linux-x64/stable" \
    | tar -zxf - -C /tmp/.vscode-server/bin/${commit_id} --strip-components=1 \
  ; tar -C /tmp -cf - .vscode-server | zstd -T0 -19 > /target/vscode-server.tar.zst \
  ;

FROM fj0rd/layer
COPY --from=build /target /srv
