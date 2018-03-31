#!/bin/sh

# Get MongoDB Image
docker pull mongo:latest

# Build images
docker build -t brdm88/post:2.0 ./post-py
docker build -t brdm88/comment:5.0 ./comment
docker build -t brdm88/ui:3.0 ./ui

# Create network and volume
docker network create reddit
docker volume create reddit_db

# Run containers from images
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post brdm88/post:2.0
docker run -d --network=reddit --network-alias=comment brdm88/comment:5.0
docker run -d --network=reddit -p 9292:9292 brdm88/ui:3.0

# Alternative network aliases test
docker run -d --network=reddit --network-alias=alt_post_db --network-alias=alt_comment_db \
-v reddit_db:/data/db \
mongo:latest

docker run -d --network=reddit --network-alias=alt_post \
--env POST_DATABASE_HOST=alt_post_db \
brdm88/post:1.0 

docker run -d --network=reddit --network-alias=alt_comment \
--env COMMENT_DATABASE_HOST=alt_comment_db \
brdm88/comment:2.0

docker run -d --network=reddit -p 9292:9292 \
--env POST_SERVICE_HOST=alt_post --env COMMENT_SERVICE_HOST=alt_comment \
brdm88/ui:1.0

