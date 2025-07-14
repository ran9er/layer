FROM ghcr.io/fj0r/io:base AS build
RUN set -eux \
  ; commit_id=$(curl -sSL https://github.com/microsoft/vscode/tags \
    | r '<a.*href="/microsoft/vscode/commit/(.+)">' -or '$1' | head -n 1) \
  ; mkdir -p /target /tmp/.vscode-server/bin/${commit_id} \
  ; curl -sSL "https://update.code.visualstudio.com/commit:${commit_id}/server-linux-x64/stable" \
    | tar -zxf - -C /tmp/.vscode-server/bin/${commit_id} --strip-components=1 \
  ; tar -C /tmp -cf - .vscode-server | zstd -T0 -19 > /target/vscode-server.tar.zst \
  ;

FROM ghcr.io/fj0r/layer
COPY --from=build /target /srv
