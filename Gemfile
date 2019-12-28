# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 6.0.0"
gem "pg", ">= 0.18", "< 2.0"
gem "puma"
gem "bootsnap", ">= 1.4.2", require: false
gem "sidekiq", require: false
gem "sidekiq-scheduler", require: false, git: "https://github.com/biow0lf/sidekiq-scheduler", branch: "ruby-2.7.0"
gem "activerecord-nulldb-adapter"

group :development, :test do
end

group :development do
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "standard", require: false
end
