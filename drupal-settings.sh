#!/bin/bash

if [ ! -e /var/www/site/docroot/sites/default/settings.php ]
  then
    /usr/local/bin/confd -onetime -backend env -confdir="/root/drupal-settings"
fi
