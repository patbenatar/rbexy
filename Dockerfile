FROM ruby:3.3.5
RUN apt-get update -qq

WORKDIR /app

COPY . .
RUN bundle
