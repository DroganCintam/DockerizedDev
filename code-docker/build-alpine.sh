#!/bin/bash

docker build \
    --build-arg ssh_pub_key="$(cat ~/.ssh/code-docker.pub)" \
    -f Dockerfile.alpine \
    -t code-docker .
