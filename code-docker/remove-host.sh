#!/bin/bash

ssh-keygen -R [localhost]:$(docker inspect --format='{{(index (index .NetworkSettings.Ports \"22/tcp\") 0).HostPort}}' code-docker)

# If you're using OrbStack, you can also use the following command:
# ssh-keygen -R code-docker.orb.local
