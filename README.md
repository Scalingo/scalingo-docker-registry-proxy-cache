# Build with bake
```bash
docker buildx bake --file docker-bake.hcl
```

# Create .env file
```bash
cp .env.sample .env
vim .env
```

# Run with docker
```bash
docker run --name openresty_docker_registry_proxy \
  --rm -it \
  -p 3128:3128 \
  -v $(pwd)/docker_mirror_cache:/docker_mirror_cache \
  -v $(pwd)/certs:/certs \
  --env-file .env \
  ${TAG}
```

# Run with docker compose
```bash
docker compose up
```

The `HTPASSWD` environment variable activates basic authentication. In this example, we define two users:
* user1:user1
* user2:user2

The `HTPASSWD_DELIMITER` environment variable can be used to specify a custom delimiter. By default, a `space` is used.

By default, `generate-certificate.sh` generates a self-signed certificate. You can override this by mounting a volume with your own certificates at `/certs`.
* server.crt
* server.key

# Configure docker to use a proxy
```json
{
  ...
  "proxies": {
    "http-proxy": "http://user1:user1@127.0.0.1:3128",
    "https-proxy": "http://user1:user1@127.0.0.1:3128"
  },
  "insecure-registries" : ["own-registry.sample.com:443"]
}
```

The `insecure-registries` setting should be configured if your proxy is using an invalid or self-signed certificate.
