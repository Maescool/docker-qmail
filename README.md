# Table of Contents
- [Introduction](#introduction)
    - [Version](#version)
- [Installation](#installation)
- [Quickstart](#quick-start)
- [Maintenance](#maintenance)
    - [Shell Access](#shell-access)
- [References](#references)

# Introduction

Dockerfile to build a container image with qmail, vpopmail, ezmlm, qmailadmin and dovecot

This container will run supervisord and start up 
- qmail-send and a qmail tcp server (for smtp)
- nginx for qmailadmin
- dovecot for imap and pop3

Take note: qmail (port 25) should NEVER be open to the public internet, it's outdated and this setup won't protect against spam.
I recommend using postfix and redirect mails for qmail-based domains to this server.

## Version

Current versions:
- qmail: **1.0.6**
- vpopmail: **5.4.33**
- ezmlm: github master version of https://github.com/bruceg/ezmlm-idx
- autorespond: **2.0.5**
- qmailadmin: **1.2.16** using ubuntu nginx
- dovecot: current ubuntu version custom rebuild: **2.2.9-1ubuntu2.1**

# Installation

I'm not planning on maintaining an docker image, but I wanted to give this to the community.
So you'll have to build it yourself, no worries, it's all automated

```bash
git clone https://github.com/Maescool/docker-qmail
cd docker-qmail
docker build -t qmail .
```
This will take a couple of minutes since it will compile everything (5 up to 30 minutes depending on your hardware).

If you want to be able to run vpopmail commands outside the container,
I've added some scripts that will help to install them:

```bash
cd assets/scripts
chmod +x install.sh
./install.sh
```

now you can use commands like `vadddomain` and `vuserinfo` etc..

# Quick Start

You can launch the image using the docker command line,

```bash
docker run --name='qmail' -it --rm \
-p 10080:80 \
-p 20025:25 -p 110:110 -p 993:993 -p 143:143 -p 995:995 \
-v /home/vpopmail/domains:/home/vpopmail/domains \
qmail
```
Point your browser to `http://localhost:10080` 

You should now have the qmailadmin application up and ready for testing. If you want to use this image in production the please read on.

# Configuration

## Data Store

if you don't want to lose your mail when the docker container is stopped/deleted. To avoid losing any data, you should mount a volume at,

* `/home/vpopmail/domains`
* `/var/qmail/control`
* `/var/qmail/users`

# Maintenance
## Shell Access

For debugging and maintenance purposes you may want access the containers shell. If you are using docker version `1.3.0` or higher you can access a running containers shell using `docker exec` command.

```bash
docker exec -it qmail bash
```

If you are using an older version of docker, you can use the [nsenter](http://man7.org/linux/man-pages/man1/nsenter.1.html) linux tool (part of the util-linux package) to access the container shell.

Some linux distros (e.g. ubuntu) use older versions of the util-linux which do not include the `nsenter` tool. To get around this @jpetazzo has created a nice docker image that allows you to install the `nsenter` utility and a helper script named `docker-enter` on these distros.

To install `nsenter` execute the following command on your host,

```bash
docker run --rm -v /usr/local/bin:/target jpetazzo/nsenter
```

Now you can access the container shell using the command

```bash
sudo docker-enter qmail
```

For more information refer https://github.com/jpetazzo/nsenter

# References

http://www.qmail.org/netqmail/
http://www.lifewithqmail.org/
http://www.inter7.com/software/

