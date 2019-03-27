ARG DEBIAN_VERSION=stretch
FROM node:8.11.4-${DEBIAN_VERSION}

# Build arguments to change source url, branch or tag
ARG DEBIAN_VERSION
ARG HACKMD_REPOSITORY=https://github.com/nexbyte/hackmd.git
ARG VERSION=master

# Set some default config variables
ENV DEBIAN_FRONTEND noninteractive
ENV DOCKERIZE_VERSION v0.6.1
ENV NODE_ENV=production

RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
    rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Add configuraton files
COPY config.json .sequelizerc /files/

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ ${DEBIAN_VERSION}-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y git postgresql-client-9.6 build-essential && \
    # Install wkhtmltopdf
    wget "https://downloads.wkhtmltopdf.org/0.12/0.12.5/wkhtmltox_0.12.5-1.${DEBIAN_VERSION}_amd64.deb" && \
    apt-get install -y xfonts-base xfonts-75dpi && \
    dpkg -i "wkhtmltox_0.12.5-1.${DEBIAN_VERSION}_amd64.deb" && \
    # Clone the source
    git clone --depth 1 --branch $VERSION $HACKMD_REPOSITORY /hackmd && \
    # Print the cloned version and clean up git files
    cd /hackmd && \
    git log --pretty=format:'%ad %h %d' --abbrev-commit --date=short -1 && echo && \
    rm -rf /hackmd/.git && \
    # Symlink configuration files
    rm -f /hackmd/config.json && ln -s /files/config.json /hackmd/config.json && \
    rm -f /hackmd/.sequelizerc && ln -s /files/.sequelizerc /hackmd/.sequelizerc && \
    # Install NPM dependencies and build project
    yarn install --pure-lockfile && \
    yarn install --production=false --pure-lockfile && \
    yarn global add webpack && \
    npm run build && \
    # Clean up this layer
    yarn install && \
    yarn cache clean && \
    apt-get remove -y --auto-remove build-essential && \
    apt-get clean && apt-get purge && rm -r /var/lib/apt/lists/* && \
    # Create hackmd user
    adduser --uid 10000 --home /hackmd/ --disabled-password --system hackmd && \
    chown -R hackmd /hackmd/

WORKDIR /hackmd
EXPOSE 3000

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 777 /usr/local/bin/docker-entrypoint.sh

# Change user after use 'chmod' to prevent errors.
USER hackmd

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["node", "app.js"]