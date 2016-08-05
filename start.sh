#!/bin/bash

# Run Confd to make config files
/usr/local/bin/confd -onetime -backend env

# Export all env vars containing "_" to a file for use with cron jobs
printenv | grep \_ | sed 's/^\(.*\)$/export \1/g' | sed 's/=/=\"/g' | sed 's/$/"/g' > /root/project_env.sh
chmod +x /root/project_env.sh

# Add gitlab to hosts file
grep -q -F "$GIT_HOSTS" /etc/hosts  || echo $GIT_HOSTS >> /etc/hosts

# Add cron jobs
sed -i "/drush/s/^\w*/$(shuf -i 1-60 -n 1)/" /root/crons.conf
crontab /root/crons.conf

# Clone repo to container
git clone -b $GIT_BRANCH $GIT_REPO /var/www/site/

# Symlink files folder
mkdir -p /mnt/sites-files/public
mkdir -p /mnt/sites-files/private
cd $APACHE_DOCROOT/sites/default && ln -sf /mnt/sites-files/public files
cd /var/www/site/ && ln -sf /mnt/sites-files/private private

# Set DRUPAL_VERSION
echo $(/usr/local/src/drush/drush --root=$APACHE_DOCROOT status | grep "Drupal version" | awk '{ print substr ($(NF), 0, 2) }') > /root/drupal-version.txt
# Install appropriate apache config and restart apache

if [[ -n "$LOCAL" &&  $LOCAL = "true" ]] ; then
  /usr/bin/apt-get update && apt-get install -y \
    php-xdebug \
    --no-install-recommends && rm -r /var/lib/apt/lists/*
  /usr/bin/supervisorctl restart php-fpm
fi

# Install appropriate apache config and restart apache
if [[ -n "$WWW" &&  $WWW = "true" ]] ; then
  cp /root/wwwsite.conf /etc/apache2/sites-enabled/000-default.conf
  /usr/bin/supervisorctl restart apache2
fi

# Import starter.sql, if needed
/root/mysqlimport.sh

# Create Drupal settings, if they don't exist
ln -s $APACHE_DOCROOT /root/apache_docroot
/root/drupal-settings.sh
