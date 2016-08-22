# docker-drupal8

Custom build for Code Koalas' Drupal 8 deployments.  

Consists of Ubuntu 16.04, PHP7 (FPM) and Apache 2.4.

# Environment variables
* VIRTUAL_HOST= FQDN of website with a "." at the beginning
* WWW= "true" if the site should redirect to www.fqdn
* PRODUCTION= "true" if the site is production (affects Git pulls and drupal settings)
* LOCAL= "true" if not in production (installs xdebug)
* GIT_HOSTS= Hosts file entry to be added
* GIT_REPO= URL of Git repo to pull from
* GIT_BRANCH= Git branch
* MYSQL_SERVER= Host name of MySQL server
* MYSQL_DATABASE= MySQL database name
* MYSQL_USER= MySQL user name
* MYSQL_PASSWORD= MySQL password
* DRUPAL_BASE_URL= Base URL for Drupal config
* DRUPAL_HTTPS= Set to on or off
* APACHE_DOCROOT= Apache Docroot - defaults to `/var/www/site/docroot`
* SESAuthUser= AWS SES SMTP username
* SESAuthPass= AWS SES SMTP password
* SESmailhub= AWS SES SMTP address

# BASH aliases
`mysqlc` connects to MySQL based on Environment Variables
`mysqld > file.sql` dumps database to file.sql based on Environment Variables

https://hub.docker.com/r/codekoalas/drupal8/
