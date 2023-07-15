if [ -n "$CODE_SERVER_WORKDIR" ]; then
    if [ -n "$CODE_SERVER_CONFIG_URL" ]; then
        curl -sSL ${CODE_SERVER_CONFIG_URL} -o /opt/code-server/user-data/User/settings.json
    fi

    /opt/code-server/bin/code-server \
        --extensions-dir /opt/code-server/extensions \
        --user-data-dir /opt/code-server/user-data \
        --disable-telemetry \
        --bind-addr 0.0.0.0:1234 \
        ${CODE_SERVER_WORKDIR}
fi
