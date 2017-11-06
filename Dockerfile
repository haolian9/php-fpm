FROM php:7.0-fpm

ENV EXT_MONGO_VERSION 1.3.2
ENV EXT_XDEBUG_VERSION 2_5_5

COPY sources.list /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

VOLUME /srv/http

WORKDIR /srv/http

RUN apt-get update && apt-get install -y libcurl4-openssl-dev \
        && docker-php-ext-install -j$(nproc) curl

RUN apt-get update && apt-get install -y libicu-dev \
        && docker-php-ext-install -j$(nproc) intl

RUN apt-get update && docker-php-ext-install -j$(nproc) \
        bcmath hash json mbstring ctype \
        mysqli pdo pdo_mysql \
        session sockets

RUN apt-get update && docker-php-ext-install -j$(nproc) \
        calendar \
        fileinfo \
        gettext \
        posix

RUN apt-get update && apt-get install -y libssl-dev \
        && cd /tmp && curl -SL 'https://github.com/mongodb/mongo-php-driver/releases/download/${EXT_MONGO_VERSION}/mongodb-${EXT_MONGO_VERSION}.tgz' | tar xzf - && cd mongodb-${EXT_MONGO_VERSION} \
        && phpize && ./configure --enable-mongodb && make -j$(nproc) && make install \
        && docker-php-ext-enable mongodb
COPY ./config/mongodb.ini /usr/local/etc/php/conf.d/mongodb.ini

RUN cd /tmp && curl -SL 'https://github.com/xdebug/xdebug/archive/XDEBUG_${EXT_XDEBUG_VERSION}.tar.gz' | tar xzf - && cd xdebug-XDEBUG_${EXT_XDEBUG_VERSION} \
        && phpize && ./configure --enable-xdebug && make -j$(nproc) && make install \
        && docker-php-ext-enable xdebug
COPY ./config/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
expose 9000

copy ./config/www.conf /usr/local/etc/php-fpm.d/www.conf

RUN mkdir -p /var/log/php-fpm

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN docker-php-ext-install -j$(nproc) zip

RUN rm -rf /tmp/*

ENTRYPOINT ["docker-entrypoint.sh"]