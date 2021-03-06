FROM ruby:2.7.0
RUN apt-get update -qq

WORKDIR /app

COPY . .
RUN bundle install
