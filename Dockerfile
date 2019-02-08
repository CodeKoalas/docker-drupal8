FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated tzdata

RUN apt-get install -y \
                ca-certificates curl cron git supervisor mysql-client vim unzip \
 		imagemagick ghostscript \
		libxml2-dev mime-support ssmtp rsync patch \
		php7.2-fpm php7.2-curl php7.2-gd php7.2-mysql php7.2-gmp php7.2-ldap php7.2-zip php7.2-mbstring \
		php7.2-bcmath php-pear php-console-table php-apcu php-mongodb php-ssh2 php7.2-soap \
		apache2 \
        --no-install-recommends && apt-get -y upgrade && rm -r /var/lib/apt/lists/*

RUN a2enmod ssl rewrite proxy_fcgi headers remoteip

RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor /var/run/php /mnt/sites-files /etc/confd/conf.d /etc/confd/templates

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer \
&& ln -s /usr/local/bin/composer /usr/bin/composer

# Install Drush
RUN git clone https://github.com/drush-ops/drush.git /usr/local/src/drush && cd /usr/local/src/drush \
&& git checkout 8.x && cd /usr/local/src/drush && composer install && ln -s /usr/local/src/drush/drush /usr/local/bin/drush

# Install Drupal Console
ADD https://drupalconsole.com/installer /usr/local/bin/drupal
RUN chmod +x /usr/local/bin/drupal 

# Install Confd
ADD https://github.com/kelseyhightower/confd/releases/download/v0.15.0/confd-0.15.0-linux-amd64 /usr/local/bin/confd
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
COPY drupal-settings /root/drupal-settings/

# Volumes
VOLUME /var/www/site /etc/apache2/sites-enabled /mnt/sites-files

EXPOSE 80

WORKDIR /var/www/site

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
