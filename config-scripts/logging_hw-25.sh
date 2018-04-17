#!/bin/sh

docker-machine create --driver google \
    --google-project=docker-194323 \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west2-a \
    --google-open-port 5601/tcp \
    --google-open-port 9292/tcp \
    --google-open-port 9411/tcp \
    logging

# configure local env
eval $(docker-machine env logging)

docker-machine ip logging

# Build microservices images
for srv in ui comment post-py; do cd src/$srv; bash docker_build.sh; cd -; done
