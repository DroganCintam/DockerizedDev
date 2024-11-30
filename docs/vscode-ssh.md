# SSH to Container with VSCode

VSCode is one of the most popular code editors and
it provides a feature to connect to remote
machines using SSH. This feature can be used to
connect to Docker containers running on the local
machine, allowing you to edit code and run
commands inside the isolated environment.

You can always skip this document and go directly
to the `code-docker` directory for example code.

## Prerequisites

- [VSCode](https://code.visualstudio.com/)
  - and the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension
- [Docker](https://www.docker.com/)
  - or [OrbStack](https://orbstack.dev/) if you are using MacOS

## SSH Configuration

### Generate SSH Key

In order for VSCode to log into a Docker
container, you will need to provide an SSH
key. This key will be used to authenticate
the connection.

The following command generates an SSH key
pair and saves it to the `.ssh` directory:

```bash
ssh-keygen -t rsa -C code@docker -f ~/.ssh/code-docker
```

2 files will be created:

- `~/.ssh/code-docker`: private key
- `~/.ssh/code-docker.pub`: public key

> In a later step, you will need to copy the
> contents of the public key file to the
> container. The SSH server in the container will
> use this key to authenticate the connection.

## Docker

### Dockerfile

The following Dockerfile sets up a basic image
with SSH server and the public key in its
corresponding location. Within this document, we
will use Alpine Linux as the base image. You can
see the Dockerfile for Ubuntu in the `code-docker`
directory.

```Dockerfile
FROM alpine

# Install SSH server
# Also libstdc++ is needed for VSCode Server
# You can install any other tools you need here
RUN apk update && \
    apk add --no-cache libstdc++ openssh-server && \
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
ENTRYPOINT /usr/sbin/sshd -D && bash
```

### Build and Run

Build the image with the following command:

```bash
docker build \
    --build-arg ssh_pub_key="$(cat ~/.ssh/code-docker.pub)" \
    -t code-docker .
```

This will create an image named `code-docker`.

Run the container with the following command:

```bash
docker run -d -it -p 22 \
    --name code-docker \
    code-docker
```

The container is now running with the name
`code-docker`. To SSH into it, you will need to
know its IP address. You can find it with the
following command:

```bash
docker inspect \
    -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
    code-docker
```

If you are using OrbStack, you can use the
domain `code-docker.orb.local` instead.

### Update SSH Configuration

Add the following section to your
`~/.ssh/config` file. If the file does not
exist, just create it.

```ssh-config
Host docker
  HostName <ip or domain>
  User root
  IdentityFile <absolute path to code-docker>
```

> The title of the host, `docker`, is arbitrary.
> You can use any title you like.

It is important to note that the path of the
`IdentityFile` should be an **absolute** path. If
you use `~` to represent your home, VSCode may
fail to find the key.

So it should be:

- `C:\Users\username\.ssh\code-docker` (Windows)
- `/Users/username/.ssh/code-docker` (MacOS)
- `/home/username/.ssh/code-docker` (Linux)

Test the connection with the following command:

```bash
ssh docker
```

If everything is set up correctly, you should
be logged into the container.

## VSCode Remote SSH

- Open VSCode.
- Press `F1` or `Ctrl+Shift+P` (`Cmd+Shift+P`) to
  open the command palette.
- Type `Remote-SSH: Connect to Host...`.
- Select the host `docker`.
- VSCode will open a new window and connect to
  the container.

## Troubleshooting

### Permission denied (publickey)

If you get this error, it means that the SSH key
is not correctly set up. Make sure that the public
key is copied into the container and that the
private key is used by VSCode (check SSH `config`
file).

### Connection closed by remote host

If you get this error, it means that the SSH
server is not running in the container. Make sure
that the SSH server is started in the `ENTRYPOINT`
of the Dockerfile.

### Connection timed out

If you get this error, it means that the container
is not running or that the IP address is
incorrect. Make sure that the container is running
and that the IP address is correct.

### Remote host key has changed

If you get this error, it means that the SSH key
of the container has changed. This can happen if
you rebuild the container or if you connect to a
different container with the same IP address. To
fix this, remove the old key from the
`~/.ssh/known_hosts` file using the following
command:

```bash
ssh-keygen -R <IP address or domain>
```