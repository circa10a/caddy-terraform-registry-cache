PROJECT=circa10a/caddy-terraform-registry-cache

build:
	xcaddy build \
		--with github.com/caddyserver/cache-handler \
		--with github.com/caddyserver/replace-response \
		--with github.com/darkweak/storages/badger/caddy
docker:
	docker build -t $(PROJECT) .
