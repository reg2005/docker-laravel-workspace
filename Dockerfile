FROM php:7.1-cli
MAINTAINER 'Evgeniy Ryumin'

# Install modules
RUN buildDeps="libpq-dev libzip-dev libicu-dev libpng12-dev libjpeg62-turbo-dev libfreetype6-dev libmagickwand-6.q16-dev" && \
    apt-get update && \
    apt-get install -y $buildDeps --no-install-recommends && \
    apt-get install -y jpegoptim pngquant optipng --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install \
        bcmath \
        pcntl \
        zip \
        opcache \
        pdo \
        pdo_pgsql \
        pgsql \
        sockets \
        intl

RUN apt-get install -y curl

RUN apt-get update && \
    apt-get install -y --no-install-recommends git zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# nvm environment variables
ENV NVM_DIR "$HOME/.nvm"
ENV NODE_VERSION 9.4.0

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash

RUN bash -c 'source $NVM_DIR/nvm.sh   && \
    nvm install node                    && \
    npm install --prefix "$HOME/.nvm/"'

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# confirm installation
RUN node -v
RUN npm -v

RUN curl -o- -L https://yarnpkg.com/install.sh | bash

#Add pa alias
RUN echo "alias pa='php artisan'" >> ~/.bashrc

RUN unlink /etc/localtime && ln -s /usr/share/zoneinfo/Etc/GMT-3 /etc/localtime

WORKDIR /var/www/html

#CRON
RUN apt-get install -y cron nano
RUN rm -rf /var/lib/apt/lists/*
RUN mkfifo --mode 0666 /var/log/cron.log
COPY ./crontab /etc/cron.d
RUN chmod -R 644 /etc/cron.d
CMD ["/bin/bash", "-c", "service cron restart && tail -f /var/log/cron.log"]

