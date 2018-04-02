#!/bin/bash

# Run Docker container from image
docker run -d --name gitlab-runner --restart always \
-v /srv/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest

# Register the Runner
docker exec -it gitlab-runner gitlab-runner register
