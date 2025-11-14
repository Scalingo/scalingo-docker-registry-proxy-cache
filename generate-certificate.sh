#!/bin/bash

if [ ! -f /certs/server.crt ]; then
  openssl genrsa -des3 -passout pass:x -out /certs/server.pass.key 2048
  openssl rsa -passin pass:x -in /certs/server.pass.key -out /certs/server.key
  rm /certs/server.pass.key
  openssl req -new -key /certs/server.key -out /certs/server.csr \
    -subj "/C=FR/ST=Grand-Est/L=Strasbourg/O=Scalingo/OU=IT Department/CN=scalingo.com"
  openssl x509 -req -days 365 -in /certs/server.csr -signkey /certs/server.key -out /certs/server.crt
fi

if [ ! -f /certs/proxy_server.crt ]; then
  openssl genrsa -des3 -passout pass:x -out /certs/proxy_server.pass.key 2048
  openssl rsa -passin pass:x -in /certs/proxy_server.pass.key -out /certs/proxy_server.key
  rm /certs/proxy_server.pass.key
  openssl req -new -key /certs/proxy_server.key -out /certs/proxy_server.csr \
    -subj "/C=FR/ST=Grand-Est/L=Strasbourg/O=Scalingo/OU=IT Department/CN=scalingo.com"
  openssl x509 -req -days 365 -in /certs/proxy_server.csr -signkey /certs/proxy_server.key -out /certs/proxy_server.crt
fi
