FROM ruby:2.7.1-alpine3.12

RUN apk add --no-cache build-base postgresql postgresql-dev libpq ssmtp mailx && \
    adduser -h /app -G users -H -D -u 1000 app && \
    mkdir /app && \
    chown app:users /app && \
    rm -rf /usr/local/bundle/cache && \
    chown -R app:users /usr/local/bundle

USER app

WORKDIR /app

COPY . .

USER root

RUN chmod -R 777 /app

USER app

RUN gem install bundler

RUN bundle install --jobs 4
