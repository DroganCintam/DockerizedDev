# Git in Container

This document describes how to set up a Docker
container with Git installed. The container can be
used to clone repositories, make changes, and push
changes back to the remote repository. We use
GitHub as an example, but the same steps can be
applied to other Git hosting services.

This guide is a continuation of the
[SSH to Container with VSCode](vscode-ssh.md)
guide. So make sure you have read it before
proceeding.

## Docker

The following Dockerfile is similar to the one we
had in the previous document, but with Git added.
We also change from `openssh-server` to `openssh`
as we need SSH client for Git.

```Dockerfile
FROM alpine

# Install Git and SSH (server and client)
# Also libstdc++ is needed for VSCode Server on Alpine
# You can install any other tools you need here
RUN apk update && \
    apk add --no-cache git openssh && \
    apk add --no-cache libstdc++ && \
    rm -rf /var/cache/apk/*

# Provide the public key as a build argument
ARG ssh_pub_key

# Prepare the key for SSH login and allow tcp forwarding
RUN mkdir /root/.ssh && \
    echo "$ssh_pub_key" > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    ssh-keygen -A && \
    sed -i s/AllowTcpForwarding.*/AllowTcpForwarding\ yes/ /etc/ssh/sshd_config

WORKDIR /home

# Start the SSH server and keep it running
ENTRYPOINT /usr/sbin/sshd -D && /bin/sh
```

As before, build the image with the following command:

```bash
docker build \
    --build-arg ssh_pub_key="$(cat ~/.ssh/code-docker.pub)" \
    -t git-docker .
```

> We use the same public key for VSCode SSH
> access, but change the image name.

Run the container with the following command:

```bash
docker run -d -it -p 22 \
    --name git-docker \
    git-docker
```

Add a new section to the `config` file:

```ssh-config
Host git-docker
    HostName localhost
    Port 12345
    User root
    IdentityFile <path to code-docker key>
```

For OrbStack, use domain instead:

```ssh-config
Host git-docker
    HostName git-docker.orb.local
    User root
    IdentityFile <path to code-docker key>
```


## GitHub SSH

To clone and push to a GitHub repo, we need to set
up an SSH key pair. The public key will be added
to your GitHub account, and the private key will
be used by Git client within the container.

### Generate SSH Key Pair

```bash
ssh-keygen -t rsa -C "docker@github" -f id_docker
```

> Leave the passphrase empty when prompted.

2 files will be created in the current directory:
- `id_docker`: private key
- `id_docker.pub`: public key

### Add the Public Key to GitHub

Go to https://github.com/settings/ssh/new and
add the content of your public key file.

### Configure SSH

Create a `config` file in the current directory
and add the following section:

```ssh-config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_docker
```

### Initialize SSH in Container

Now copy the private key and `config` file to the
container.

```bash
docker cp id_docker git-docker:/root/.ssh/
docker cp config git-docker:/root/.ssh/
```

We need to set the correct permissions for the
private key.

```bash
docker exec git-docker chmod 600 /root/.ssh/id_docker
```

Also, we need to change the owner of the private
key and `config` file.

```bash
docker exec git-docker chown root:root /root/.ssh/id_docker
docker exec git-docker chown root:root /root/.ssh/config
```

### Git Clone

Now you can clone a repository from GitHub. Log
into the container using `ssh git-docker` or
VSCode Remote SSH as described in the previous
document, then run the following command:

```bash
git clone git@github.com:<username>/<repo>.git
```
