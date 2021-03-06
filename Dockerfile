ARG php_version=7.0
FROM php:${php_version}-fpm

LABEL maintainer="Ryan Gellis <ryan.gellis@rmgmedia.com>"

# Install Base Packages
RUN apt-get update && apt-get install -y \
  apt-transport-https \
  apt-utils \
  git \
  gnupg \
  libcurl3-dev \
  libfreetype6-dev \
  libjpeg-dev \
  libmcrypt-dev \
  libpng-dev \
  libxml2-dev \
  libxslt-dev \
  openssh-client \
  zlib1g-dev
  
# Install PHP Extensions
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/lib \
  && docker-php-ext-install bcmath ctype curl dom fileinfo gd iconv intl json \
  && docker-php-ext-install mbstring mcrypt opcache pdo_mysql posix simplexml \
  && docker-php-ext-install soap tokenizer xml xmlwriter xsl zip 

# xdebug comes from pecl
RUN pecl install xdebug-2.6.0

# zlib has a broken bit - workaround https://github.com/docker-library/php/issues/233#issuecomment-288727629
RUN docker-php-ext-install zlib; exit 0
RUN cp /usr/src/php/ext/zlib/config0.m4 /usr/src/php/ext/zlib/config.m4
RUN docker-php-ext-install zlib


# Configure PHP
COPY config/php.ini /usr/local/etc/php/php.ini
  
# Node Setup
RUN curl -sS https://deb.nodesource.com/setup_10.x | bash
RUN apt-get install -y nodejs

# Gulp setup
RUN npm install --global gulp-cli

# Yarn Setup
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install --no-install-recommends yarn  
  
# Cleanup
RUN rm -rf /var/lib/apt/lists/*

# Ioncube what a pain
WORKDIR /root/
RUN curl -sS https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o ioncube_loader.tgz
RUN tar -zxvf ioncube_loader.tgz
WORKDIR /root/ioncube
RUN cp ioncube_loader_lin_7.0.so /usr/local/lib/php/extensions/no-debug-non-zts-20151012/ioncube_loader_lin_7.0.so
WORKDIR /root/
RUN rm -rf ioncube*

# Setup webuser
RUN useradd -d /home/webuser -m -u 800 webuser

# Switch to Webuser
USER webuser
WORKDIR /home/webuser

# Install composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && php composer-setup.php --install-dir=/home/webuser/ --filename=composer
RUN rm -f composer-setup.php

RUN echo "alias conductor=/home/webuser/conductor/vendor/bin/conductor" >> /home/webuser/.bashrc
RUN echo "alias composer=/home/webuser/composer" >> /home/webuser/.bashrc

