#!/usr/bin/env bash

function test_success_docker_debian_pull() {
  function foo() {
    return 0
  }

  docker pull debian:13-slim

  assert_successful_code
}

function test_success_docker_tag_debian_image() {
  function foo() {
    return 0
  }

  docker tag debian:13-slim my-registry.local:443/debian:13-slim

  assert_successful_code
}

function test_success_docker_push_debian_image_to_local_registry_through_proxy() {
  function foo() {
    return 0
  }

  docker push my-registry.local:443/debian:13-slim

  assert_successful_code
}

function test_success_docker_rm_local_debian_images() {
  function foo() {
    return 0
  }

  docker rmi debian:13-slim my-registry.local:443/debian:13-slim

  assert_successful_code
}

function test_success_docker_pull_debian_image_from_local_registry_through_proxy() {
  function foo() {
    return 0
  }

  docker pull my-registry.local:443/debian:13-slim

  assert_successful_code
}

function test_failed_docker_pull_debian_image_from_unknown_registry_through_proxy() {
  function foo() {
    return 0
  }

  docker pull my-registryX.local:443/debian:13-slim

  assert_unsuccessful_code
}

function test_failed_curl_request_to_unknwon_registry_through_proxy() {
  function foo() {
    return 0
  }

  assert_equals "403" "$(curl -I -x https://user1:password1@my-proxy.local:3128 https://my-registry-x.local:443/v2/_catalog 2> /dev/null | head -n 1 | cut -d' ' -f2)"
}

function test_failed_curl_request_to_proxy_without_user() {
  function foo() {
    return 0
  }

  assert_equals "407" "$(curl -I -x https://my-proxy.local:3128 https://my-registry.local:443/v2/_catalog 2> /dev/null | head -n 1 | cut -d' ' -f2)"
}

function test_failed_curl_request_to_proxy_with_wrong_creds() {
  function foo() {
    return 0
  }

  assert_equals "401" "$(curl -I -x https://user1:dummy@my-proxy.local:3128 https://my-registry.local:443/v2/_catalog 2> /dev/null | head -n 1 | cut -d' ' -f2)"
}
