#!/bin/sh

docker pull mongo:latest

docker build -t brdm88/post:1.0 ./post-py
docker build -t brdm88/comment:1.0 ./comment
docker build -t brdm88/ui:1.0 ./ui

docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post brdm88/post:1.0
docker run -d --network=reddit --network-alias=comment brdm88/comment:1.0
docker run -d --network=reddit -p 9292:9292 brdm88/ui:1.0

docker volume create reddit_db
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
