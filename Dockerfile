FROM fj0rd/io:base as build

ENV TARGET=/target
ENV NODE_ROOT=/opt/node
ENV NVIM_ROOT=/opt/nvim
ENV PATH=${NODE_ROOT}/bin:${NVIM_ROOT}/bin:$PATH

ENV XDG_CONFIG_HOME=/opt/config

ENV NVIM_PRESET=core \
    PYTHONUNBUFFERED=x

RUN set -eux \
  ; apt update \
  ; apt-get install -y --no-install-recommends gnupg build-essential \
  ; mkdir -p ${TARGET} \
  \
  ; mkdir -p /opt/node \
  ; node_version=$(curl -sSL https://nodejs.org/en/download/ | rg 'Latest LTS Version.*<strong>(.+)</strong>' -or '$1') \
  ; curl -sSL https://nodejs.org/dist/v${node_version}/node-v${node_version}-linux-x64.tar.xz \
    | tar Jxf - --strip-components=1 -C /opt/node \
  \
  ; mkdir -p /opt/language-server \
  ; npm install --location=global \
        quicktype \
        pyright \
        vscode-langservers-extracted \
        yaml-language-server \
  ; npm cache clean -f \
  ; tar -C /opt -cf - node | zstd -T0 -19 > $TARGET/node.tar.zst \
  \
  ; lua_ls_url=$(curl -sSL https://api.github.com/repos/sumneko/lua-language-server/releases -H 'Accept: application/vnd.github.v3+json' \
               | jq -r '[.[]|select(.prerelease == false)][0].assets[].browser_download_url' | grep 'linux-x64') \
  ; mkdir -p /opt/language-server/sumneko_lua \
  ; curl -sSL ${lua_ls_url} | tar zxf - \
      -C /opt/language-server/sumneko_lua \
  ; tar -C /opt/language-server -cf - sumneko_lua | zstd -T0 -19 > $TARGET/nvim-lua.tar.zst \
  \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN set -eux \
  ; mkdir -p $NVIM_ROOT \
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


FROM fj0rd/0x:or
RUN set -eux \
  ; tar -C /opt -cf - openresty | zstd -T0 -19 > /srv/openresty.tar.zst
COPY --from=build /target /srv
COPY setup.sh /srv
