FROM ruby:2.7 AS builder

RUN apt-get update && apt-get install -y netcat

WORKDIR /app
COPY . /app/
RUN gem install bundler -v 2.3.26
RUN bundle install

RUN chmod +x /app/entrypoint.sh
CMD ["/app/entrypoint.sh"]
