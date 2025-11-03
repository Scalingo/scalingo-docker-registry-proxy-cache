#!/bin/bash

# Vars
CERTS_PATH="/root/certs"
DOCKER_PATH="/var/lib/docker"
DOCKER_MIRROR_CACHE_PATH="/docker_mirror_cache"

# Add proxy to docker
if [ ! -d /etc/systemd/system/docker.service.d ]; then
  mkdir /etc/systemd/system/docker.service.d
  cat << 'EOF' > /etc/systemd/system/docker.service.d/proxy.conf
[Service]
Environment="NO_PROXY=*.docker.io,*.cloudflarestorage.com"
Environment="HTTPS_PROXY=https://user1:password1@my-proxy.local:3128"
EOF
fi

# Install packages
apt-get update
apt-get install -y docker.io docker-compose docker-buildx apache2-utils

# Start and enable docker
systemctl is-active --quiet docker || systemctl enable docker
systemctl is-active --quiet docker || systemctl start docker

if [ ! -f ${CERTS_PATH}/custom_ca.key ]; then
  # Generate certificates
  mkdir -p ${CERTS_PATH}
  ## CA
  openssl genrsa -out ${CERTS_PATH}/custom_ca.key 4096
  openssl req -x509 -new -nodes -key ${CERTS_PATH}/custom_ca.key -sha256 -days 3650 -subj "/C=AU/ST=Some-State/O=MyOrg/CN=local"  -out ${CERTS_PATH}/custom_ca.crt

  ## Proxy CRT
  openssl genrsa -out ${CERTS_PATH}/proxy_server.key 4096
  openssl req -new -sha256 \
    -key ${CERTS_PATH}/proxy_server.key \
    -subj "/C=AU/ST=Some-State/O=ORG/OU=ORG_UNIT/CN=my-proxy.local" \
    -reqexts SAN \
    -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=DNS:my-proxy.local")) \
    -out ${CERTS_PATH}/proxy_server.csr
  openssl x509 -req -extfile <(printf "subjectAltName=DNS:my-proxy.local") -days 3650 -in ${CERTS_PATH}/proxy_server.csr -CA ${CERTS_PATH}/custom_ca.crt -CAkey ${CERTS_PATH}/custom_ca.key -CAcreateserial -out ${CERTS_PATH}/proxy_server.crt -sha256

  ## Docker-registry CRT
  openssl genrsa -out ${CERTS_PATH}/server.key 4096
  openssl req -new -sha256 \
    -key ${CERTS_PATH}/server.key \
    -subj "/C=AU/ST=Some-State/O=ORG/OU=ORG_UNIT/CN=my-registry.local" \
    -reqexts SAN \
    -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\nsubjectAltName=DNS:my-registry.local")) \
    -out ${CERTS_PATH}/server.csr
  openssl x509 -req -extfile <(printf "subjectAltName=DNS:my-registry.local") -days 3650 -in ${CERTS_PATH}/server.csr -CA ${CERTS_PATH}/custom_ca.crt -CAkey ${CERTS_PATH}/custom_ca.key -CAcreateserial -out ${CERTS_PATH}/server.crt -sha256

  #Add ca-cert to system
  cp ${CERTS_PATH}/custom_ca.crt /usr/local/share/ca-certificates
  update-ca-certificates
fi

grep -q "my-proxy.local" /etc/hosts
if [[ $? != 0 ]]; then
  echo "127.0.0.1 my-proxy.local" >> /etc/hosts
fi

# Build image
docker buildx bake --file /vagrant/docker-bake.hcl --set *.context=/vagrant

# Create docker network
docker network inspect registry >/dev/null 2>&1 || docker network create registry

# Run docker registry container
if [ ! "$(docker ps -a -q -f name=my-registry)" ]; then
  docker run -dit --name my-registry \
    --hostname my-registry.local \
    -v ${CERTS_PATH}:/certs \
    -v ${DOCKER_MIRROR_CACHE_PATH}/docker-registry:/var/lib/registry \
    -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.crt \
    -e REGISTRY_HTTP_TLS_KEY=/certs/server.key \
    --network registry \
    registry:2
fi

# Run docker registry cache container
if [ ! "$(docker ps -a -q -f name=openresty_docker_registry_proxy)" ]; then
  mkdir ${DOCKER_MIRROR_CACHE_PATH}/docker-cache/
  chown 1001:1001 ${DOCKER_MIRROR_CACHE_PATH}/docker-cache/
  chown 1001:1001 ${CERTS_PATH}/*server.{crt,key}
  docker run -dit --name openresty_docker_registry_proxy \
    -p 3128:3128 \
    -v ${DOCKER_MIRROR_CACHE_PATH}/docker-cache/:/docker_mirror_cache \
    -v ${CERTS_PATH}:/certs \
    -e VERIFY_SSL=false \
    -e CACHE_MAX_SIZE=5G \
    -e ALLOW_PUSH=true \
    -e ENABLE_MANIFEST_CACHE=false \
    -e REGISTRIES=my-registry.local \
    -e ALLOW_UNKNOWN_REGISTRIES=false \
    -e HTPASSWD=$(htpasswd -nbB user1 password1) \
    --network registry \
    docker-registry-proxy-cache:latest
fi
