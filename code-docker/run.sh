#!/bin/bash

docker run -d -it -p 2222:22 \
    --name code-docker \
    code-docker
