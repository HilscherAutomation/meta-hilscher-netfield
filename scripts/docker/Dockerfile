FROM crops/yocto:ubuntu-20.04-base

USER root

RUN apt-get update && \
    apt-get install -y libssl-dev zip subversion ncurses-dev python3-pexpect && \
    apt-get install -y ca-certificates && \
    apt-get install -y efitools uuid-runtime && \
    apt-get install -y liblz4-tool zstd && \
    apt-get clean

# To allow the testability, add a jenkins user for our build server.
RUN useradd jenkins-host --home-dir /var/jenkins_home --uid 10000 --shell /bin/bash

USER yoctouser

ENV LANG=en_US.UTF-8
ENV TERM=xterm-color

WORKDIR /build
