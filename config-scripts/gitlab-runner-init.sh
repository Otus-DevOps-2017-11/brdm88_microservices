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
