ARG BASE_IMAGE="openresty-proxy-connect"

FROM ${BASE_IMAGE}

COPY generate-certificate.sh /generate-certificate.sh
COPY entrypoint.sh /entrypoint.sh

COPY nginx.conf /opt/openresty/nginx/conf/nginx.conf
COPY nginx.manifest.common.conf /opt/openresty/nginx/conf/nginx.manifest.common.conf
COPY nginx.manifest.stale.conf /opt/openresty/nginx/conf/nginx.manifest.stale.conf
COPY proxy_auth.lua /opt/openresty/nginx/conf/proxy_auth.lua

RUN apk add --no-cache --update bash openssl \
  && mkdir -p /docker_mirror_cache /certs /opt/openresty/nginx/tmp \
  && bash -c 'mkdir -p /opt/openresty/nginx/tmp/{client_body,proxy,fastcgi,scgi,uwsgi}' \
  && chmod +x /generate-certificate.sh /entrypoint.sh \
  && chmod -R g+rwX /opt/openresty/nginx/conf \
  && chmod g+rwX /certs \
  && chmod -R g+rwX /opt/openresty/nginx/tmp

VOLUME /docker_mirror_cache
VOLUME /certs

EXPOSE 3128

## Default envs.
# A space delimited list of registries we should proxy and cache; this is in addition to the central DockerHub.
ENV REGISTRIES="registry.k8s.io gcr.io quay.io ghcr.io"
# A space delimited list of registry:user:password to inject authentication for
ENV AUTH_REGISTRIES="some.authenticated.registry:oneuser:onepassword another.registry:user:password"
# Should we verify upstream's certificates? Default to true.
ENV VERIFY_SSL="true"

# Manifest caching tiers. Disabled by default, to mimick 0.4/0.5 behaviour.
# Setting it to true enables the processing of the ENVs below.
# Once enabled, it is valid for all registries, not only DockerHub.
# The envs *_REGEX represent a regex fragment, check entrypoint.sh to understand how they're used (nginx ~ location, PCRE syntax).
ENV ENABLE_MANIFEST_CACHE="false"

# 'Primary' tier defaults to 10m cache for frequently used/abused tags.
# - People publishing to production via :latest (argh) will want to include that in the regex
# - Heavy pullers who are being ratelimited but don't mind getting outdated manifests should (also) increase the cache time here
ENV MANIFEST_CACHE_PRIMARY_REGEX="(stable|nightly|production|test)"
ENV MANIFEST_CACHE_PRIMARY_TIME="10m"

# 'Secondary' tier defaults any tag that has 3 digits or dots, in the hopes of matching most explicitly-versioned tags.
# It caches for 60d, which is also the cache time for the large binary blobs to which the manifests refer.
# That makes them effectively immutable. Make sure you're not affected; tighten this regex or widen the primary tier.
ENV MANIFEST_CACHE_SECONDARY_REGEX="(.*)(\d|\.)+(.*)(\d|\.)+(.*)(\d|\.)+"
ENV MANIFEST_CACHE_SECONDARY_TIME="60d"

# The default cache duration for manifests that don't match either the primary or secondary tiers above.
# In the default config, :latest and other frequently-used tags will get this value.
ENV MANIFEST_CACHE_DEFAULT_TIME="1h"

# Should we allow actions different than pull, default to false.
ENV ALLOW_PUSH="false"

# If push is allowed, buffering requests can cause issues on slow upstreams.
# If you have trouble pushing, set this to false first, then fix remainig timouts.
# Default is true to not change default behavior.
ENV PROXY_REQUEST_BUFFERING="true"

# Timeouts
# ngx_http_core_module
ENV SEND_TIMEOUT="60s"
ENV CLIENT_BODY_TIMEOUT="60s"
ENV CLIENT_HEADER_TIMEOUT="60s"
ENV KEEPALIVE_TIMEOUT="300s"
# ngx_http_proxy_module
ENV PROXY_READ_TIMEOUT="60s"
ENV PROXY_CONNECT_TIMEOUT="60s"
ENV PROXY_SEND_TIMEOUT="60s"
# ngx_http_proxy_connect_module - external module
ENV PROXY_CONNECT_READ_TIMEOUT="60s"
ENV PROXY_CONNECT_CONNECT_TIMEOUT="60s"
ENV PROXY_CONNECT_SEND_TIMEOUT="60s"

# Allow disabling IPV6 resolution, default to false
ENV DISABLE_IPV6="false"

# Forbid unknown registries
ENV ALLOW_UNKNOWN_REGISTRIES="false"

USER 1001

# Did you want a shell? Sorry, the entrypoint never returns, because it runs nginx itself. Use 'docker exec' if you need to mess around internally.
ENTRYPOINT ["/entrypoint.sh"]
