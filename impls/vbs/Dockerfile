FROM ubuntu:20.04
MAINTAINER Joel Martin <github@martintribe.org>

##########################################################
# General requirements for testing or common across many
# implementations
##########################################################

RUN apt-get -y update

# Required for running tests
RUN apt-get -y install make python3
RUN ln -fs /usr/bin/python3 /usr/local/bin/python

RUN mkdir -p /mal
WORKDIR /mal

##########################################################
# Specific implementation requirements
##########################################################

# skip the geographic area selection
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Shanghai
ENV VBS_MAL_ENV=WINE
ENV WINEPREFIX=/mal/.wine

RUN dpkg --add-architecture i386
RUN apt update
RUN apt install wine32 winetricks -y
RUN wine winecfg
RUN winetricks -q wsh57
RUN wine cmd /c echo hello,world
RUN wine cscript
