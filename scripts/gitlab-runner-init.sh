#!/bin/bash

# Run Docker container from image (for using with docker-machine)
docker run -d --name gitlab-runner --restart always \
-e GOOGLE_APPLICATION_CREDENTIALS=/etc/gitlab-runner/gce-docker.json \
-v /srv/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest

# Register the Runner
docker exec -it gitlab-runner gitlab-runner register


## Runner Autoscale Config

# Create container registry
docker run -d -p 6000:5000 \
    -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
    --restart always \
    --name registry registry:2

# Create cache server
docker run -it --restart always -p 9005:9000 \
        -v /.minio:/root/.minio \
        -v /export:/export \
        --name minio \
        minio/minio:latest server /export

mkdir /export/runner
cat /.minio/config.json

# config.toml file contents
concurrent = 5
check_interval = 0
[[runners]]
  name = "brdm88-runner"
  url = "http://35.189.107.99/"
  token = "cdf0e03905d72353127cf6a67ec425"
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
  [runners.cache]
[[runners]]
  name = "brdm88-autoscale-runner"
  url = "http://35.189.107.99"
  token = "14ff323c8d1fbfb8e9b9b047165584"
  executor = "docker+machine"
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
  [runners.cache]
    type = "s3"
    ServerAddress = "35.189.107.99:9005"
    AccessKey = "UGJNFYK4TJKHR9XYCPNO"
    SecretKey = "yj5ZJJbeSWEdhAf9kyOc13SCtg3aCTODIIjjqrUo"
    BucketName = "runner"
    Insecure = true
  [runners.machine]
    IdleCount = 0
    MachineDriver = "google"
    MachineName = "runner-autoscale-%s"
    MachineOptions = [
      "google-project=docker-194323",
      "google-machine-type=g1-small",
      "google-machine-image=ubuntu-os-cloud/global/images/ubuntu-1604-xenial-v20180405",
      "google-tags=default-allow-ssh",
      "google-zone=europe-west2-a",
      "google-use-internal-ip=true"
    ]
    OffPeakTimezone = ""
    OffPeakIdleCount = 0
    OffPeakIdleTime = 0
