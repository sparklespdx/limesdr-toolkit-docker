# LimeSDR Toolkit

This is a container built on Ubuntu 18.04 that contains LimeSuite, Soapy, GNURadio, and GQRX.
It should serve as a good foundation for building other software stacks with LimeSDR.

## Why does this exist?

When starting to do research on SDR software stacks so I could get my LimeSDR up and running, I realized that there's a bit of a dependency hell problem:

* Installing LimeSDR on OSX worked fine, but trying to get GNURadio and GQRX working was a nightmare.
* GQRX and GNURadio installation on Fedora 25 worked fine, but there was zero support for building LimeSDR and Soapy on Fedora.
* The only OS where there is build support for both is Ubuntu 16.04 (and to a lesser extent 18.04)

Instead of trying to troubleshoot a Fedora build for LimeSuite and Soapy and write RPMs that immediately go stale, I decided to put this stuff in a Docker container. This is easier for me to maintain and keeps the dependency hell localized to the container. It also means we are using supported(ish) versions of the build and runtime libraries.

I'm hoping that doing this work will make it simple and easy for another person to run a couple commands and get their LimeSDR up and running on the host distro that they prefer.

## Getting Started
* Make sure the Docker daemon is installed and running.

* Make sure your user has a uid and gid of 1000 or edit `run.sh` and `build.sh` to match your uid and gid. NOTE: I'm gonna fix this.

* Run `mkdir -p ~/radiodev` to set up a home dir for the running container.

* To build the docker container, run `sh ./build.sh` from the project root. This builds a container with the name `limesdr-toolkit`.

* You can now run programs like this: `sh ./run.sh LimeUtil --find`. Or you can just run `sh ./run.sh` to get a bash shell in the container.

## Notes

The first thing you should do when you build the container is run `volk_profile`. This will increase performance significantly. By default this configuration is saved to ~/radiodev on the host.

We're using Ubuntu 18.04 instead of the officially supported 16.04 because HiDPI support isn't included in the versions of QT that are officially available in 16.04, and HiDPI support is a requirement for me. If you have a HiDPI display, you need to set `QT_SCALE_FACTOR` in your host environment. 1.4 works well for me. For more information, see https://wiki.archlinux.org/index.php/HiDPI

`run.sh` mounts some host directories into the container:
  * `/tmp/.X11-unix` so we can start X programs.
  * `/run/user/1000/pulse/native` so we can use PulseAudio.
  * `/dev/bus/usb` so we can use host USB devices.

It also mounts `~/radiodev` to the home directory of the container's primary user, which is named radiodev. This is to save persistent configurations for our SDR software.

The container drops to user 1000:1000 when it starts (default user in Red Hat based distros). The container runs in privileged mode to get the USB and X11 stuff to work, but the processes it launches do not run as root. We could probably do this without launching the container as root, but I haven't figured it out yet.

## FAQ

### Will this run on Docker for Mac?

Short answer: no.

Long answer: Docker for Mac runs a Linux VM using Hyperkit, which doesn't have USB forwarding support. There's an old version of Docker for Mac that runs on Virtualbox which might possibly work, or you could roll your own Docker host VM in a hypervisor that supports USB forwarding. I cannot support these use cases and I don't recommend trying; my experience with Virtualbox on Macs leaves something to be desired when it comes to performance and performance is pretty critical to this application. I've basically given up on running gnuradio software on OSX for now. Maybe I'll try again with SDRAngel.

### Will this run on (some version of Linux that isn't Fedora 25)?

I don't know. Probably. Try it out and let me know how it goes.

## TODO

* Get this working without having to run the container with privileges
* Make the build aware of the building user's UID and GID and set up the radiodev user with those values.
* Test on other host operating systems
