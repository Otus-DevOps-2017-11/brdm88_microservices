#!/bin/sh

gcloud compute firewall-rules create prometheus-default --allow tcp:9090
gcloud compute firewall-rules create puma-default --allow tcp:9292

export GOOGLE_PROJECT=docker-194323

# create docker host
docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    vm1

# configure local env
eval $(docker-machine env vm1)

docker run --rm -p 9090:9090 -d --name prometheus  prom/prometheus

docker-machine ip vm1

docker stop prometheus


export USER_NAME=brdm88
docker build -t $USER_NAME/prometheus .

# Build microservices images
for srv in ui comment post-py; do cd src/$srv; bash docker_build.sh; cd -; done

docker-compose down --remove-orphans

curl -X POST -H 'Content-type: application/json' \
--data '{"text":"Webhook Test"}' \
 https://hooks.slack.com/services/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

