FROM registry.docker.com/library/ruby:3.2.2-slim as base

LABEL maintainer="Igor Zubkov <igor.zubkov@gmail.com>"

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    BOOTSNAP_LOG="true" \
    BOOTSNAP_READONLY="true" \
    RUBY_YJIT_ENABLE="1"

RUN set -eux; \
    gem update --system "3.5.3" ; \
    gem install bundler --version "2.5.3" --force ; \
    gem --version ; \
    bundle --version

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
# skipcq: DOK-DL3008
RUN set -eux; \
    apt-get update -qq ; \
    apt-get dist-upgrade -qq ; \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config shared-mime-info

# Install application gems
COPY .ruby-version Gemfile Gemfile.lock ./
RUN set -eux; \
    bundle install ; \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git ; \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Workaround for nokogiri and trivy
RUN rm -f /usr/local/bundle/ruby/3.2.0/gems/nokogiri-1.15.5-x86_64-linux/dependencies.yml

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN set -eux; \
    apt-get update -qq ; \
    apt-get dist-upgrade -qq ; \
    apt-get install --no-install-recommends -y curl postgresql-client libjemalloc2 shared-mime-info ; \
    apt-get autoremove -y ; \
    apt-get clean -y ; \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN set -eux; \
    useradd rails --create-home --shell /bin/bash ; \
    chown -R rails:rails db log tmp

USER rails:rails

ENV LD_PRELOAD="libjemalloc.so.2"

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000/tcp

CMD ["./bin/rails", "server"]
