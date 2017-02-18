# Docker iRedmail container
#
# This allows one to run iRedMail inside a container. This is useful as iRedMail
# really wants to be installed on a virgin O/S install and does not play well
# with other software, even if installed later. I kmow: I've tried. It does
# not end well.
#
# Procedure:
#
# 1. Build this Docker file into an image:
#
#	docker build . -t <iRedMail image name>
#
# 2. Run the image the first time to get iRedMail installed in it and configured
#    Sadly, since iRedMail depends on proper service start/stop management,
#    we need something that it understands to do this, like systemd, packaged
#    with debian:jessie, and that requires us to run the image privileged.
#
#	docker run --privileged -ti \
#           --name <iRedMail container name> \
#	    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#           -v /var/vmail:/var/vmail \
#           -p 25:25 -p 465:465 -p 587:587 \
#           -p 110:110 -p 143:143 -p 993:993 -p 995:995 \
#           -p 80:80 -p 443:4433 \
#	    <iRedMail image name>
#
#    Here we indicate what ports will be exposed and where mail will be stored
# (/var/vmail) on the host. If you wish, it can stay stored in the container
# by omitting the related -v clause.
#
#    iRedMail has a rather complex and convolutied installation and
# configuration process, and this lets us use it as it. The intent is to produce
# a container that's ready to go.
#
#     You will be prompted for the mail server's host name, and then things will
# proceed as per usual iRedMail configuration (including downloading and
# installing software, so have an internet connection up). Select the default
# /var/vmail location for map. You can remap it on the host if you wish (or use
# an alternate and remap differently, but there really is no reason to unless
# you're going to be making some kind of derived Docker image that precludes
# this). You should accept the default firewall rules (they apply WITHIN the
# container and are fine), and restart the firewall when prompted.
#
#     When this completes (about 20 minutes with a decent CPU and fast internet
# connection), you will have a container with iRedmail installed and configured!
# BE CAREFUL WITH THIS: iRedMail does not like to have it's processes shut down
# ungracefully, particularly mysql. I have spent many an hour recovering a
# corrupted database. You will have to shut down the container GRACEFULLY!
#
#     The iRedMail installation and configuratuion is ready when you see:
#
#	[  OK  ] Reached target Multi-User System.
#
# 3) Start a shell session from another terminal in the newly created container
#    and shut it down:
#
#	docker exec -it <container name> bash
#	shutdown now
#
#    You now have an iRedMail container ready to go! You can start it up and
# and administer it the way you usually would: All the required ports are
# exposed from the container, and you just have to point your browser at it's
# network address when you start it up. Ensure that the mail server hostname
# you provided to it resolves to it. (For local testing, just add it to
# /etc/hosts in your host machine).
#
# 4) If you wish to commit the configured container to an image snapshot
#    simply execute:
#
#	docker commit <container name> <iRedMail image name>
#
# 5) You can run this image via
#
#	docker run --privileged -ti \
#	    --name <iRedMail container name> \
#	    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#	    -v /var/vmail:/var/vmail \
#	    -p 25:25 -p 465:465 -p 587:587 \
#	    -p 110:110 -p 143:143 -p 993:993 -p 995:995 \
#	    -p 80:80 -p 443:4433 \
#	    <iRedMail image name>
#
#     Conversely, if you have a stopped container of that image, you can
# restart it via:
#
#	docker start -i <iRedMail container name>>
#
#     It is ready for you to connect to it via port 80 or 443 to administer
# like any other iRedMail server.
#
#     Enjoy!
#
# P.S. Yes, the resulting configured image is fat, very FAT, at just under
# 1 GB. However, iRedMail expects a rather complete O/S install and no effort
# was made to slim this down.
#
# P.P.S. REMEMBER TO STOP THE CONTAINER GRACEFULLY via shutdown now within it!
# It may be wise to keep one's email outside the container as this does, and
# commit a new container snapshot every time one makes a configuration change
# so one has an image to revert to if their gets corrupted.
#

FROM debian:jessie
MAINTAINER "Rene S. Hollan" <rene@hollan.org>

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update; apt-get install -y apt-utils wget bzip2
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN \
    wget https://bitbucket.org/zhb/iredmail/downloads/iRedMail-0.9.6.tar.bz2;\
    tar -jxvf iRedMail-0.9.6.tar.bz2; \
    chmod +x iRedMail-0.9.6/iRedMail.sh; \
    systemctl set-default multi-user.target

# Install systemd oneshot startup script to configure iRedMail on first start.

COPY rc.local /etc/rc.local
COPY rc-local.service /lib/systemd/system/rc-local.service
RUN \
    chmod +x /etc/rc.local; \
    cd /lib/systemd/system/multi-user.target.wants; \
    ln -s ../rc-local.service rc-local.service;

# Mail Server ports, Mail Client ports, Web main/admin ports
EXPOSE 25 465 587  110 143 993 995  80 443

ENV init /lib/systemd/systemd
VOLUME [ "/sys/fs/cgroup" ]
VOLUME [ "/var/vmail" ]
ENTRYPOINT ["/lib/systemd/systemd"]
