FROM ruby:3.2.3
RUN apt-get update -qq

WORKDIR /app

COPY . .
RUN bundle
RUN bundle exec appraisal bundle
