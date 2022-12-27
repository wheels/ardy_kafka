#!/bin/bash
set -e

until nc -vz broker 29092
do
    echo "Waiting for Kafka ..."
    sleep 1
done

echo -e "\n Yeah! Kafka is up now"
bundle exec rspec
