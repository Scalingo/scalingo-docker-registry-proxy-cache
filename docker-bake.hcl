variable "TAG" {
  default = "docker-registry-proxy-cache:latest"
}

group "default" {
  targets = ["docker-registry-proxy-cache"]
}

target "openresty-proxy-connect" {
  dockerfile = "Dockerfile.openresty"
}

target "docker-registry-proxy-cache" {
  tags = [ TAG ]
  dockerfile = "Dockerfile"
  contexts = {
    openresty-proxy-connect = "target:openresty-proxy-connect"
  }
}
