###############################################################################
#####              https://github.com/jotrocken   | 25.01.2023            #####
###############################################################################
FROM ubuntu:20.04

LABEL author="Jonas" url="https://github.com/jotrocken" version="1.1"
LABEL description="Ubuntu 20.04 based SSH server with pubkey authentication only, \
can also be used as SSH reverse tunnel endpoint."

# Install SSH-Server, create user "tunnel"
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y sudo openssh-server && \
    apt-get upgrade -y && \
    useradd -m -s /bin/bash tunnel && \
    echo "tunnel:docker" | chpasswd && \
    usermod -aG sudo tunnel && \
    mkdir -p /home/tunnel/.ssh/ && \
    chown -R tunnel /home/tunnel && \
    mkdir -p -m0755 /var/run/sshd

# Modify SSHD config file: root login/pwd authentication not allowed, only pubkey auth allowed
RUN sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#GatewayPorts no/GatewayPorts yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#ClientAliveInterval 0/ClientAliveInterval 600/' /etc/ssh/sshd_config && \
    sed -i 's/^#PermitTunnel no/PermitTunnel yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#LogLevel INFO/LogLevel VERBOSE/' /etc/ssh/sshd_config

# COPY authorized_keys /home/tunnel/.ssh/
VOLUME ["/home/tunnel/.ssh/"]

# Feel free to use ports 4401-4403 for other purposes (like SSH reverse tunnel endpoints)
EXPOSE 22 4401 4402 4403

CMD ["/usr/sbin/sshd", "-D", "-e"]
