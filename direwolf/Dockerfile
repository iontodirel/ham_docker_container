# **************************************************************** #
# ham_docker_container - Containers for APRS and ham radio         #
# Version 0.1.0                                                    #
# https://github.com/iontodirel/ham_docker_container               #
# Copyright (c) 2023 Ion Todirel                                   #
# **************************************************************** #

FROM ubuntu:23.04

RUN apt-get update -y
RUN apt-get install -y alsa-tools alsa-utils
RUN apt-get install -y direwolf
RUN apt-get install -y gcc g++ make cmake libasound2-dev libudev-dev git
RUN apt-get install -y jq

ENV FIND_DEVICES=/find_devices/find_devices

RUN git clone https://github.com/iontodirel/find_devices.git
WORKDIR /find_devices
RUN cmake .
RUN make -j 4

RUN mkdir /direwolf
WORKDIR /direwolf
COPY ./start_direwolf.sh start_direwolf.sh
RUN chmod +x start_direwolf.sh

CMD /direwolf/start_direwolf.sh
