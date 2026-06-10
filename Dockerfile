FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && apt-get install -y -qq \
    build-essential \
    gcc \
    make \
    kmod \
    golang-go \
    docker.io \
    docker-compose-v2 \
    cron \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app