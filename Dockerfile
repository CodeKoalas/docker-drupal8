FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
                ca-certificates curl cron git supervisor mysql-client vim unzip \
		libxml2-dev mime-support ssmtp \
		imagemagick ghostscript \
		php7.0-fpm php7.0-curl php7.0-gd php7.0-mysql php7.0-mcrypt php7.0-gmp php7.0-ldap php7.0-zip \
		php7.0-bcmath php-pear php-console-table php-apcu php-mongodb \
		apache2 \
        --no-install-recommends && apt-get -y upgrade && rm -r /var/lib/apt/lists/*

RUN a2enmod ssl rewrite proxy_fcgi headers remoteip

# Install New Relic daemon
RUN echo newrelic-php5 newrelic-php5/application-name string "AppName" | debconf-set-selections && \
    echo newrelic-php5 newrelic-php5/license-key string "12345asdfg54321gfdsa" | debconf-set-selections
ENV NR_INSTALL_SILENT true
RUN env && curl https://download.newrelic.com/548C16BF.gpg | apt-key add - && \
    echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list && \
    apt-get update && apt-get -y install newrelic-php5

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
COPY www.conf /etc/php/7.0/fpm/pool.d/www.conf
COPY php.ini /etc/php/7.0/fpm/php.ini
COPY site.conf /etc/apache2/sites-available/000-default.conf
COPY remoteip.conf /etc/apache2/conf-enabled/remoteip.conf
COPY confd /etc/confd/
COPY apache2.conf /etc/apache2/apache2.conf
COPY registry_rebuild /root/.drush/registry_rebuild

# Copy in drupal-specific files
COPY wwwsite.conf drupal-settings.sh crons.conf start.sh mysqlimport.sh mysqlexport.sh load-configs.sh xdebug-php.ini /root/
COPY bash_aliases /root/.bash_aliases
COPY drupal7-settings /root/drupal7-settings/
COPY drupal8-settings /root/drupal8-settings/

# Volumes
VOLUME /var/www/site /etc/apache2/sites-enabled /mnt/sites-files

EXPOSE 80

WORKDIR /var/www/site

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
