#!/bin/sh

# Create GCE Instance for running Docker

docker-machine create --driver google \
--google-project docker-194323  \
--google-zone europe-west2-a \
--google-machine-type n1-standard-1 \
--google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
docker-host
