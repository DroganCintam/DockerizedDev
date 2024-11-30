#!/bin/bash

ssh-keygen -R $(docker inspect \
    -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
    code-docker)

# If you're using OrbStack, you can also use the following command:
# ssh-keygen -R code-docker
