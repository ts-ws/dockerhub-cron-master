#UPDATE-TIMESTAMP_20201012154503
FROM debian:latest
RUN apt-get update && \
	apt-get -y upgrade && \
    apt-get -y install htop && \
	apt-get -y install apache2 php php-mysql
EXPOSE 80
CMD ["/usr/sbin/apache2ctl","-DFOREGROUND"]
