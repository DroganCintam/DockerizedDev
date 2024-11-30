#!/bin/bash

# Copy the key and the config
docker cp id_docker git-docker:/root/.ssh/
docker cp config git-docker:/root/.ssh/

# Change the permissions
docker exec git-docker chmod 600 /root/.ssh/id_docker

# Change the owner
docker exec git-docker chown root:root /root/.ssh/id_docker
docker exec git-docker chown root:root /root/.ssh/config
