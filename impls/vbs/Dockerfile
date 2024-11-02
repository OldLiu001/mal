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
ENV TZ=Asia/Shanghai

RUN dpkg --add-architecture i386
RUN apt update
RUN apt install xvfb wine32 winetricks -y
RUN winetricks -q wsh57
RUN xvfb-run -a --server-args="-screen 0 1280x800x24 -nolisten tcp" winetricks -q dotnet35
