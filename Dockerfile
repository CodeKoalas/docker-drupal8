FROM ubuntu:16.04

RUN apt-get update && apt-get install -y python-software-properties software-properties-common \
  --no-install-recommends --allow-unauthenticated
RUN add-apt-repository ppa:ondrej/php -y | echo 0
RUN apt-get update && apt-get install -y --allow-unauthenticated --no-install-recommends \
    ca-certificates curl cron git supervisor mysql-client vim unzip libxml2-dev mime-support ssmtp \
    php7.2-fpm php7.2-curl php7.2-gd php7.2-mysql php7.2-gmp php7.2-ldap php7.2-zip \
    php7.2-bcmath php-pear php-console-table php-apcu php-mongodb php-ssh2 \
    apache2 && apt-get -y --allow-unauthenticated upgrade && rm -r /var/lib/apt/lists/*

RUN a2enmod ssl rewrite proxy_fcgi headers remoteip

RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor /var/run/php /mnt/sites-files /etc/confd/conf.d /etc/confd/templates

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer \
&& ln -s /usr/local/bin/composer /usr/bin/composer

# Install Drush
RUN git clone https://github.com/drush-ops/drush.git /usr/local/src/drush && cd /usr/local/src/drush \
&& git checkout 8.1.9 && cd /usr/local/src/drush && composer install && ln -s /usr/local/src/drush/drush /usr/local/bin/drush

# Install Drupal Console
ADD https://drupalconsole.com/installer /usr/local/bin/drupal
RUN chmod +x /usr/local/bin/drupal 

# Install Confd
ADD https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 /usr/local/bin/confd
RUN chmod +x /usr/local/bin/confd

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY www.conf /etc/php/7.2/fpm/pool.d/www.conf
COPY php.ini /etc/php/7.2/fpm/php.ini
COPY site.conf /etc/apache2/sites-available/000-default.conf
COPY remoteip.conf /etc/apache2/conf-enabled/remoteip.conf
COPY confd /etc/confd/
COPY apache2.conf /etc/apache2/apache2.conf
COPY registry_rebuild /root/.drush/registry_rebuild

# Copy in drupal-specific files
COPY wwwsite.conf drupal-settings.sh crons.conf start.sh mysqlimport.sh mysqlexport.sh mysqldropall.sh load-configs.sh xdebug-php.ini post-merge /root/
COPY bash_aliases /root/.bash_aliases
COPY drupal7-settings /root/drupal7-settings/
COPY drupal8-settings /root/drupal8-settings/

# Volumes
VOLUME /var/www/site /etc/apache2/sites-enabled /mnt/sites-files

EXPOSE 80

WORKDIR /var/www/site

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
