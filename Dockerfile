FROM fj0rd/scratch:dropbear as dropbear
FROM fj0rd/scratch:nu as nu

FROM fj0rd/io:base as build

ENV TARGET=/target
ENV NODE_ROOT=/opt/node
ENV NVIM_ROOT=/opt/nvim
ENV NU_ROOT=/opt/nushell
ENV UTILS_ROOT=/opt/utils
ENV LS_ROOT=/opt/language-server
ENV SSHD_ROOT=/opt/dropbear
ENV PATH=${NODE_ROOT}/bin:${NVIM_ROOT}/bin:$PATH

ENV XDG_CONFIG_HOME=/opt/config

ENV NVIM_PRESET=core \
    PYTHONUNBUFFERED=x


# base
RUN set -eux \
  ; apt update \
  ; apt-get install -y --no-install-recommends gnupg build-essential \
  ; mkdir -p ${TARGET} \
  ; mkdir -p $NVIM_ROOT \
  ; mkdir -p $NODE_ROOT \
  ; mkdir -p $UTILS_ROOT \
  ; mkdir -p $LS_ROOT \
  ; mkdir -P $NU_ROOT \
  ; mkdir -P $SSHD_ROOT \
  \
  ;

# node
RUN set -eux \
  ; node_version=$(curl -sSL https://nodejs.org/en/download/ | rg 'Latest LTS Version.*<strong>(.+)</strong>' -or '$1') \
  ; curl -sSL https://nodejs.org/dist/v${node_version}/node-v${node_version}-linux-x64.tar.xz \
    | tar Jxf - --strip-components=1 -C $NODE_ROOT \
  \
  # lspy lsyaml lsjson
  ; npm install --location=global \
        quicktype \
        pyright \
        vscode-langservers-extracted \
        yaml-language-server \
  ; npm cache clean -f \
  ; tar -C $(dirname $NODE_ROOT) -cf - $(basename $NODE_ROOT)| zstd -T0 -19 > $TARGET/node.tar.zst \
  \
  # lslua
  ; lua_ls_url=$(curl -sSL https://api.github.com/repos/sumneko/lua-language-server/releases -H 'Accept: application/vnd.github.v3+json' \
               | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep 'linux-x64') \
  ; mkdir -p $LS_ROOT/sumneko_lua \
  ; curl -sSL ${lua_ls_url} | tar zxf - \
      -C $LS_ROOT/sumneko_lua \
  ; tar -C $LS_ROOT -cf - sumneko_lua | zstd -T0 -19 > $TARGET/lslua.tar.zst \
  \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* \
  \
  # lsnode
  ; git clone --depth=1 https://github.com/microsoft/vscode-node-debug2.git $LS_ROOT/vscode-node-debug2 \
  ; cd $LS_ROOT/vscode-node-debug2 \
  ; npm install \
  ; NODE_OPTIONS=--no-experimental-fetch npm run build \
  ; tar -C $LS_ROOT -cf - vscode-node-debug2 | zstd -T0 -19 > $TARGET/lsnode.tar.zst \
  # lsphp
  ; git clone --depth=1 https://github.com/xdebug/vscode-php-debug.git $LS_ROOT/vscode-php-debug \
  ; cd $LS_ROOT/vscode-php-debug \
  ; npm install && npm run build \
  ; tar -C $LS_ROOT -cf - vscode-php-debug | zstd -T0 -19 > $TARGET/lsphp.tar.zst \
  ;

# nvim
RUN set -eux \
  ; nvim_url=$(curl -sSL https://api.github.com/repos/neovim/neovim/releases -H 'Accept: application/vnd.github.v3+json' \
             | jq -r '[.[]|select(.prerelease==false)][0].assets[].browser_download_url' | grep -v sha256sum | grep linux64.tar.gz) \
  ; curl -sSL ${nvim_url} | tar zxf - -C $NVIM_ROOT --strip-components=1 \
  ; tar -C $(dirname $NVIM_ROOT) -cf - $(basename $NVIM_ROOT) | zstd -T0 -19 > $TARGET/nvim.tar.zst \
  \
  ; mkdir -p ${XDG_CONFIG_HOME} \
  ; git clone --depth=1 https://github.com/fj0r/nvim-lua.git $XDG_CONFIG_HOME/nvim \
  ; git clone --depth=1 https://github.com/wbthomason/packer.nvim $XDG_CONFIG_HOME/nvim/pack/packer/start/packer.nvim \
  ; nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' \
  \
  ; tsl=$(cat $XDG_CONFIG_HOME/nvim/lua/lang/treesitter_lang.json|jq -r 'join(" ")') \
  ; nvim --headless -c "TSUpdateSync ${tsl}" -c 'quit' \
  ; rm -rf $XDG_CONFIG_HOME/nvim/pack/packer/*/*/.git \
  ; tar -C ${XDG_CONFIG_HOME} -cf - nvim | zstd -T0 -19 > $TARGET/nvim.conf.tar.zst

# nushell
RUN set -eux \
  ; zoxide_url=$(curl -sSL https://api.github.com/repos/ajeetdsouza/zoxide/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep x86_64-unknown-linux-musl) \
  ; curl -sSL ${zoxide_url} | tar zxf - -C $NU_ROOT zoxide \
  \
  ; nu_url=$(curl -sSL https://api.github.com/repos/nushell/nushell/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep x86_64-unknown-linux-musl) \
  ; curl -sSL ${nu_url} | tar zxf - -C $NU_ROOT --strip-components=1 --wildcards '*/nu*' \
  ; tar -C $(dirname $NU_ROOT) -cf - $(basename $NU_ROOT) | zstd -T0 -19 > $TARGET/nushell.tar.zst \
  ; git clone --depth=1 https://github.com/fj0r/nushell.git ${HOME}/.config/nushell \
  ; tar -C ${HOME}/.config -cf - nushell | zstd -T0 -19 > $TARGET/nushell.conf.tar.zst \
  ;

# utils
COPY --from=nu /usr/local/bin/dog $UTILS_ROOT/dog
RUN set -eux \
  ; rg_url=$(curl -sSL https://api.github.com/repos/BurntSushi/ripgrep/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep x86_64-unknown-linux-musl) \
  ; curl -sSL ${rg_url} | tar zxf - -C $UTILS_ROOT --strip-components=1 --wildcards '*/rg' \
  \
  ; yq_url=$(curl -sSL https://api.github.com/repos/mikefarah/yq/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep 'linux_amd64.tar') \
  ; curl -sSL ${yq_url} | tar zxf - && mv yq_linux_amd64 $UTILS_ROOT/yq \
  \
  ; fd_url=$(curl -sSL https://api.github.com/repos/sharkdp/fd/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep x86_64-unknown-linux-musl) \
  ; curl -sSL ${fd_url} | tar zxf - -C $UTILS_ROOT --strip-components=1 --wildcards '*/fd' \
  \
  ; sd_url=$(curl -sSL https://api.github.com/repos/chmln/sd/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep x86_64-unknown-linux-musl) \
  ; curl -sSL ${sd_url} -o $UTILS_ROOT/sd && chmod +x $UTILS_ROOT/sd \
  \
  ; just_url=$(curl -sSL https://api.github.com/repos/casey/just/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep x86_64-unknown-linux-musl) \
  ; curl -sSL ${just_url} | tar zxf - -C $UTILS_ROOT just \
  \
  ; watchexec_url=$(curl -sSL https://api.github.com/repos/watchexec/watchexec/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease==false and (.tag_name|startswith("cli")))][0].assets[].browser_download_url' | grep 'x86_64-unknown-linux-musl.tar') \
  ; curl -sSL ${watchexec_url} | tar Jxf - --strip-components=1 -C $UTILS_ROOT --wildcards '*/watchexec' \
  \
  ; btm_url=$(curl -sSL https://api.github.com/repos/ClementTsang/bottom/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep x86_64-unknown-linux-musl) \
  ; curl -sSL ${btm_url} | tar zxf - -C $UTILS_ROOT btm \
  \
  ; dust_url=$(curl -sSL https://api.github.com/repos/bootandy/dust/releases -H 'Accept: application/vnd.github.v3+json' \
          | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep x86_64-unknown-linux-musl) \
  ; curl -sSL ${dust_url} | tar zxf - -C $UTILS_ROOT --strip-components=1 --wildcards '*/dust' \
  \
  ; find $UTILS_ROOT -type f -exec grep -IL . "{}" \; | xargs -L 1 strip -s \
  ; tar -C $(dirname $UTILS_ROOT) -cf - $(basename $UTILS_ROOT) | zstd -T0 -19 > $TARGET/utils.tar.zst \
  ;

# sshd
COPY --from=dropbear / $SSHD_ROOT
RUN set -eux \
  ; tar -C $(dirname $SSHD_ROOT) -cf - $(basename $SSHD_ROOT) | zstd -T0 -19 > $TARGET/sshd.tar.zst \

FROM fj0rd/0x:latest as openresty
RUN set -eux \
  ; mkdir -p /target \
  ; tar -C /opt -cf - openresty | zstd -T0 -19 > /target/openresty.tar.zst

FROM fj0rd/scratch:py as python

FROM fj0rd/0x:or
COPY --from=build /target /srv
COPY --from=openresty /target /srv
COPY --from=python /python.tar.zst /srv
COPY setup.sh /srv
