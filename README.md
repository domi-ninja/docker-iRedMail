# docker-iRedMail
Dockerized version of iRedMail that uses systemd to actually make iRedMail services work.

    This allows one to run iRedMail inside a container. This is useful as
iRedMail really wants to be installed on a virgin O/S install and does not
play well with other software, even if installed later. I kmow: I've tried.
It does not end well.

Procedure:

1. Build this Docker file into an image:

	docker build . -t <iRedMail image name>

2. Run the image the first time to get iRedMail installed in it and configured
   Sadly, since iRedMail depends on proper service start/stop management,
   we need something that it understands to do this, like systemd, packaged
   with debian:jessie, and that requires us to run the image privileged.

	docker run --privileged -ti \
          --name <iRedMail container name> \
	    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
          -v /var/vmail:/var/vmail \
          -p 25:25 -p 465:465 -p 587:587 \
          -p 110:110 -p 143:143 -p 993:993 -p 995:995 \
          -p 80:80 -p 443:4433 \
	    <iRedMail image name>

   Here we indicate what ports will be exposed and where mail will be stored
(/var/vmail) on the host. If you wish, it can stay stored in the container
by omitting the related -v clause.

   iRedMail has a rather complex and convolutied installation and
configuration process, and this lets us use it as it. The intent is to produce
a container that's ready to go.
