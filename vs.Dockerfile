FROM fj0rd/io:base as build

FROM fj0rd/layer
COPY --from=build /target /srv
