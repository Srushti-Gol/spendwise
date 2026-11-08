FROM ruby:3.3-slim AS base

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential libpq-dev curl nodejs npm git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

FROM base AS deps
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 --without development test

FROM deps AS build
COPY . .
ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=1
RUN SECRET_KEY_BASE=placeholder bundle exec rails assets:precompile 2>/dev/null || true

FROM ruby:3.3-slim AS runtime
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libpq-dev curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=1
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
