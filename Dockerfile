FROM ruby:3.1.1
RUN apt-get update -qq

WORKDIR /app

COPY . .
RUN bundle
RUN bundle exec appraisal bundle 
