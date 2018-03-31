#!/bin/sh

docker run --network none --rm -d --name net_test joffotron/docker-net-tools -c "sleep 100"
docker exec -it net_test ifconfig

docker run --network host --rm -d --name net_test joffotron/docker-net-tools -c "sleep 100"
docker exec -it net_test ifconfig
docker-machine ssh docker-host ifconfig

docker run --network host -d nginx

sudo ln -s /var/run/docker/netns /var/run/netns
sudo ip netns

docker network create back_net --subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24

# Run containers from images
docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
docker run -d --network=back_net --name post brdm88/post:1.0
docker run -d --network=back_net --name comment brdm88/comment:1.0
docker run -d --network=front_net --name ui -p 9292:9292 brdm88/ui:1.0

docker network connect front_net post
docker network connect front_net comment

### DOCKER-COMPOSE

export USERNAME=brdm88

docker-compose up -d
docker-compose ps