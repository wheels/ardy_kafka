FROM ruby:2.7 AS builder

RUN apt-get update && apt-get install -y netcat

RUN gem install bundler:2.3.26

WORKDIR /app
COPY . /app/
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

RUN bundle install

RUN chmod +x /app/entrypoint.sh
CMD ["/app/entrypoint.sh"]
