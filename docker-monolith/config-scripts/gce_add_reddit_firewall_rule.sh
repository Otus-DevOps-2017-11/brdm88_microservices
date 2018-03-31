#!/bin/sh

# Add firewall rule to access Puma web server

gcloud compute firewall-rules create reddit-app \
--allow tcp:9292 --priority=65534 \
--target-tags=docker-machine \
--description="Allow TCP connections to port 9292" \
--direction=INGRESS
