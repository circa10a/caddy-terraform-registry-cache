FROM caddy:builder AS builder
RUN xcaddy build \
    --with github.com/caddyserver/cache-handler \
    --with github.com/caddyserver/replace-response \
    --with github.com/darkweak/storages/badger/caddy

FROM caddy
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY ./Caddyfile /etc/caddy/
