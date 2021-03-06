FROM ruby:3.0.0
RUN apt-get update -qq

WORKDIR /app

COPY . .
RUN bundle install
