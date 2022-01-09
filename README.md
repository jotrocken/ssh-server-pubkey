# [Docker] SSH server for public key authentication and as SSH tunnel endpoint

## Overview

This SSH server is based on Ubuntu 20.04 and focussed on connection security and suitable as a SSH tunnel endpoint.\
It has the following features and thereby differences to other SSH server images:

- SSH user is (for security purposes) **not** allowed to authenticate with password
- private key can be created by yourself on your own system
- as many different publickeys as you want/need
- no root login allowed
- image is prepared as a **SSH reverse tunnel *endpoint***

## Installation

**You need a docker host to install.**

#### Create directories
First create a working directory and it's subdirectory for the public keys on the host:

```
git clone https://github.com/jotrocken/ssh-server-pubkey.git
cd ssh-server-pubkey
```

#### Create keypair

If you already have a RSA keypair, please add it `cat <publickeyfile> keys/authorized_keys` and skip to the next step.

Generate a keypair (public/private) and copy the public key into the right directory (later on this will be a mounted volume).\
If you want an automatically established SSH connection, **don't assign a password** for the keyfile!

```
ssh-keygen -f sshkey -t rsa -b 4096
chmod 600 sshkey
cat sshkey.pub >> keys/authorized_keys
```

#### Run container

```
docker run -d \
       -p 4422:22 \
       -v ./keys/:/home/tunnel/.ssh/ \
       --name ssh-server \
       --restart unless-stopped \
       jotrocken/ssh-server-pubkey
````

#### Compose container instead

`docker-compose up -d`

#### Connect!

Now it's time to try it out! From the docker host, find out the private IP of the container by `docker inspect ssh-server`, there you find the IP address: `"IPAddress": ...`\
Get a connection: `ssh tunnel@[IP] -p 4422 -i sshkey`\
That's it!

To get a connection from an external machine, move the private keyfile `sshkey` to that system, adjust your firewall settings on the Docker host `(open port 4422)`, then\
`ssh tunnel@[dockerhost-public-IP] -p 4422 -i sshkey`

__*Be informed, that your username is **tunnel**, the password (not usable for SSH login, but for `sudo` for example) is **docker**, but you're advised to change it after login:*__ `passwd`


---
---
---
## Optional
#### Add more keyfiles *(optional)*

The second, third, fourth... key can be added by `cat <pubkey-filename> >> keys/authorized_keys`

#### SSH reverse tunnel endpoint

I use the following systems at home that provide a HTTP-, SSH- or other login possibility:

- Raspberry Pi
- surveillance camera
- heating control
- smart home tools like plugs to control over internet

Unfortunately my internet connection has no reachable public IP (because of `CGNAT`), also DynDNS doesn't work because of this. Usually this stuff is connectable to if you're at our home LAN, but not from outside.\
I establish a SSH reverse tunnel to a VPS (docker host), there is this container running.

**How to do that?**

- create new container of this image with minimum one more published port: `-p 4401:4401` or 
- `docker-compose -f docker-compose-reversetunnel.yml -d`
- create a keypair (see above)
- find out to which port you need to make a connection on that device
- find out the LAN IP of that device and make the IP static in the router settings
- now make a reverse SSH tunnel from that device or any other device in your LAN that "speaks" SSH:

```
ssh tunnel@[public-IP-of-dockerhost] -p 4422 -i sshkey -fN -R [port-on-home-device]:[LAN-IP-of-home-device]:4401

e.g.:    ssh tunnel@211.212.213.214 -p 4422 -i sshkey -fN -R 22:192.168.9.112:4401
```
I recommend to use `autossh` instead of ssh.

- now you can connect to [public-IP-of-dockerhost]:4401 (think about firewall settings on the docker host!)
- at this container the ports 4401, 4402 and 4403 are ready for this kind of backroute to the dockerhost.

## What's next

Coming soon...:

- adding fail2ban
- make image size smaller (Alpine?)
- shell script for preparing installation
- optional TOTF authentication (2FA)
