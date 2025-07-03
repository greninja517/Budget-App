FROM ruby:3.1.2 AS builder

RUN apt update -qq && apt install -y build-essential libpq-dev nodejs npm

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install

COPY package.json package-lock.json ./
RUN npm ci --only=production

COPY . .
RUN SECRET_KEY_BASE="dummy_secret" bundle exec rails assets:precompile

# stage 2
FROM ruby:3.1.2-slim

RUN apt update -qq && apt install -y --no-install-recommends libpq5 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the bundled gems and application code from the builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app .

# Set production environment variables
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true

EXPOSE 3000

ENTRYPOINT [ "bundle", "exec" ]
CMD [ "rails", "server"]