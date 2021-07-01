#ManualUpdateTimestamp:20201012113000
#AutomaticUpdateTimestamp:20210702000505

FROM ubuntu:latest

MAINTAINER Technik Service Whitesheep <support@ts-ws.de>

ARG DEBIAN_FRONTEND=noninteractive

#Update and Basic Apps
RUN apt-get update && \
    apt-get -y upgrade

RUN apt-get -y install bash curl psmisc  && \
    apt-get -y install htop bmon nmon dnsutils iputils-ping net-tools  && \
    apt-get -y install nano vim less gawk expect moreutils bsdmainutils  && \
    apt-get -y install rsync sshpass git

#Docker needed Apps
RUN apt-get -y install cron rsyslog logrotate mysql-client

RUN apt-get -y install openssh-server && \
    mkdir -p -m0755 /var/run/sshd

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install postfix libsasl2-modules bsd-mailx

RUN ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    /usr/sbin/dpkg-reconfigure -f noninteractive tzdata

#Additional needed Apps
RUN apt-get -y install python unattended-upgrades

#apt cleanup
RUN apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/log/apt

EXPOSE 61000

COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
