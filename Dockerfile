FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
                ca-certificates curl cron git supervisor mysql-client\
		libxml2-dev mime-support ssmtp \
		php7.0-fpm php7.0-curl php7.0-gd php7.0-mysql php7.0-mcrypt php7.0-gmp php7.0-ldap  \
		php-pear php-console-table php-apcu php-mongodb \
		apache2 \
        --no-install-recommends && apt-get -y upgrade && rm -r /var/lib/apt/lists/*

RUN a2enmod ssl rewrite proxy_fcgi headers remoteip

RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor /var/run/php /mnt/sites-files /etc/confd/conf.d /etc/confd/templates

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer \
&& ln -s /usr/local/bin/composer /usr/bin/composer

# Install Drush
RUN git clone https://github.com/drush-ops/drush.git /usr/local/src/drush && cd /usr/local/src/drush \
&& git checkout 8.1.2 && cd /usr/local/src/drush && composer install && ln -s /usr/local/src/drush/drush /usr/local/bin/drush

# Install Drupal Console
ADD https://drupalconsole.com/installer /usr/local/bin/drupal
RUN chmod +x /usr/local/bin/drupal && /usr/local/bin/drupal init --override && /usr/local/bin/drupal settings:set checked "true"

# Install Confd
ADD https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 /usr/local/bin/confd
RUN chmod +x /usr/local/bin/confd

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY www.conf /etc/php/7.0/fpm/pool.d/www.conf
COPY php.ini /etc/php/7.0/fpm/php.ini
COPY site.conf /etc/apache2/sites-available/000-default.conf
COPY remoteip.conf /etc/apache2/conf-enabled/remoteip.conf
COPY confd /etc/confd/
COPY apache2.conf /etc/apache2/apache2.conf

# Copy in drupal-specific files
COPY wwwsite.conf drupal-settings.sh crons.conf start.sh mysqlimport.sh /root/
COPY drupal7-settings /root/drupal7-settings/
COPY drupal8-settings /root/drupal8-settings/

# Volumes
VOLUME /var/www/site /etc/apache2/sites-enabled /mnt/sites-files

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
