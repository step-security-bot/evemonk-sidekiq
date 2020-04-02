FROM ruby:2.7.1-slim

LABEL maintainer="Igor Zubkov <igor.zubkov@gmail.com>"

RUN apt-get update -y && \
    apt-get dist-upgrade -y && \
    apt-get install git gcc make wait-for-it libpq-dev --no-install-recommends -y

RUN apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app

WORKDIR /app

COPY Gemfile Gemfile

COPY Gemfile.lock Gemfile.lock

ENV RAILS_ENV production

ENV RUBYGEMS_VERSION 3.1.2

RUN gem update --system "$RUBYGEMS_VERSION"

ENV BUNDLER_VERSION 2.1.4

RUN gem install bundler --version "$BUNDLER_VERSION" --force

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config set --global frozen 1

# two jobs
RUN bundle config set --global jobs 2

# install only production gems without development and test
RUN bundle config set --global without development test

# retry 5 times before fail
RUN bundle config set --global retry 5

RUN bundle install

COPY . .

# RUN bundle exec rake SECRET_KEY_BASE=blablabla DB_ADAPTER=nulldb assets:precompile

EXPOSE 3000/tcp

ENTRYPOINT ./bin/app.sh
