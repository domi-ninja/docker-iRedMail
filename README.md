# docker-iRedMail
Dockerized version of iRedMail that uses systemd to actually make iRedMail services work.

This allows one to run iRedMail inside a container. This is useful as iRedMail really wants to be installed on a virgin O/S install and does not play well with other software, even if installed later. I kmow: I've tried. It does not end well.

Procedure:

1. Build this Docker file into an image:

    docker build . -t &lt;iRedMail image name&gt;

2. Run the image the first time to get iRedMail installed in it and configured
   Sadly, since iRedMail depends on proper service start/stop management,
   we need something that it understands to do this, like systemd, packaged
   with debian:jessie, and that requires us to run the image privileged.

    docker run --privileged -ti \  
        --name &lt;iRedMail container name&gt; \  
	-v /sys/fs/cgroup:/sys/fs/cgroup:ro \  
        -v /var/vmail:/var/vmail \  
        -p 25:25 -p 465:465 -p 587:587 \  
        -p 110:110 -p 143:143 -p 993:993 -p 995:995 \  
        -p 80:80 -p 443:443 \  
	&lt;iRedMail image name&gt;

Here we indicate what ports will be exposed and where mail will be stored (/var/vmail) on the host. If you wish, it can stay stored in the container by omitting the related -v clause.

iRedMail has a rather complex and convolutied installation and configuration process, and this lets us use it as it. The intent is to produce a container that's ready to go.

You will be prompted for the mail server's host name, and then things will proceed as per usual iRedMail configuration (including downloading and installing software, so have an internet connection up). Select the default /var/vmail location for map. You can remap it on the host if you wish (or use an alternate and remap differently, but there really is no reason to unless you're going to be making some kind of derived Docker image that precludes this). You should accept the default firewall rules (they apply WITHIN the container and are fine), and restart the firewall when prompted.

 When this completes (about 20 minutes with a decent CPU and fast internet connection), you will have a container with iRedmail installed and configured! BE CAREFUL WITH THIS: iRedMail does not like to have it's processes shut down ungracefully, particularly mysql. I have spent many an hour recovering a corrupted database. You will have to shut down the container GRACEFULLY!

The iRedMail installation and configuratuion is ready when you see:

    [  OK  ] Reached target Multi-User System.

3) Start a shell session from another terminal in the newly created container and shut it down:

    docker exec -it &lt;container name&gt; shutdown now

You now have an iRedMail container ready to go! You can start it up and and administer it the way you usually would: All the required ports are exposed from the container, and you just have to point your browser at it's network address when you start it up. Ensure that the mail server hostname you provided to it resolves to it. (For local testing, just add it to /etc/hosts in your host machine).

4) If you wish to commit the configured container to an image snapshot simply execute:

    docker commit &lt;container name&gt; &lt;iRedMail image name&gt;

5) You can run this image via

    docker run --privileged -ti \  
        --name &lt;RedMail container name&gt; \  
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \  
        -v /var/vmail:/var/vmail \  
        -p 25:25 -p 465:465 -p 587:587 \  
        -p 110:110 -p 143:143 -p 993:993 -p 995:995 \  
        -p 80:80 -p 443:4433 \  
        &lt;iRedMail image name&gt;

Conversely, if you have a stopped container of that image, you can restart it via:

    docker start -i &lt;iRedMail container name&gt;

It is ready for you to connect to it via port 80 or 443 to administer like any other iRedMail server.

Enjoy!

P.S. Yes, the resulting configured image is fat, very FAT, at just under 1 GB. However, iRedMail expects a rather complete O/S install and no effort was made to slim this down.

P.P.S. REMEMBER TO STOP THE CONTAINER GRACEFULLY via shutdown now within it! It may be wise to keep one's email outside the container as this does, and commit a new container snapshot every time one makes a configuration change so one has an image to revert to if their gets corrupted.
