FROM ubuntu

# Provide the public key as a build argument
ARG ssh_pub_key

# Prepare the key for SSH login
RUN mkdir /root/.ssh && \
    echo "$ssh_pub_key" > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Install SSH server
# You can install any other tools you need here
RUN apt update && \
    apt install -y openssh-server && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home

# Start the SSH server and keep it running
ENTRYPOINT service ssh start && bash
