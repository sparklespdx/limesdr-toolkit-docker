FROM ubuntu:18.04

RUN export DEBIAN_FRONTEND=noninteractive
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y software-properties-common

# PPAs
RUN add-apt-repository -y ppa:myriadrf/drivers && \
    add-apt-repository -y ppa:myriadrf/gnuradio && \
    add-apt-repository -y ppa:gqrx/gqrx-sdr && \
    apt-get -y update

# Install GNURadio and GQRX from PPA
# TODO: Install both from source so we can be more portable.
#RUN apt-get -y install gqrx-sdr
RUN apt-get -y install gqrx-sdr soapysdr-tools soapysdr-module-lms7


# Build deps
# TODO: Validate
RUN apt-get install -y cmake g++ libpython-dev python-numpy swig \
		git g++ cmake libsqlite3-dev libsoapysdr-dev libi2c-dev \
		libusb-1.0-0-dev libwxgtk3.0-dev freeglut3-dev \
		libboost-all-dev python-mako doxygen python-docutils \
		build-essential wget

# Build some stuff from source
# All of this gets installed as dependencies to gqrx, only install
# if we need fresh builds.

#ENV LD_PRELOAD_DIR /usr/local/lib:/usr/local/lib64

# Soapy is installed with gqrx
#WORKDIR /home/base
#RUN git clone https://github.com/pothosware/SoapySDR.git
#RUN git clone https://github.com/pothosware/SoapyRTLSDR.git
#RUN git clone https://github.com/steve-m/librtlsdr.git

#WORKDIR /home/base/SoapySDR/build
#RUN cmake ../ && make -j4 && make install && ldconfig
#WORKDIR /home/base/SoapyRTLSDR/build
#RUN cmake ../ && make -j4 && make install && ldconfig
#WORKDIR /home/base/librtlsdr/build
#RUN cmake ../ && make -j4 && make install && ldconfig

# These are not included in the gqrx package install
WORKDIR /home/base
RUN git clone https://github.com/myriadrf/LimeSuite.git
RUN git clone https://github.com/sparklespdx/gr-limesdr.git

WORKDIR /home/base/LimeSuite/builddir
RUN cmake ../ && make -j4 && make install && ldconfig
WORKDIR /home/base/gr-limesdr/build
RUN cmake ../ && make -j4 && make install && ldconfig

# Set up user for X forwarding and dropping privs
# NOTE: My uid is 1000, yours might not be.
RUN apt-get -y install sudo

WORKDIR /home
RUN rm -rf base
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN export uid=1000 gid=1000 && \
    mkdir -p /home/radiodev && \
    echo "radiodev:x:${uid}:${gid}:Radiodev,,,:/home/radiodev:/bin/bash" >> /etc/passwd && \
    echo "radiodev:x:${uid}:" >> /etc/group && \
    echo "radiodev ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/radiodev && \
    chmod 0440 /etc/sudoers.d/radiodev && \
    chown ${uid}:${gid} -R /home/radiodev && \
    gpasswd -a radiodev audio

COPY 64-limesuite.rules /etc/udev/rules.d/
COPY pulse-client.conf /etc/pulse/client.conf
USER radiodev
# This takes forever; run when container is running and ~ is mounted.
#RUN volk_profile
WORKDIR /home/radiodev
ENV HOME /home/radiodev
