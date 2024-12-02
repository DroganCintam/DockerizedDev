#!/bin/bash

docker run -d -it -p 2222:22 \
    --name git-docker \
    git-docker
