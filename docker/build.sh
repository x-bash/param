#! /usr/bin/env bash

docker build --no-cache -t xcmd/debian:latest -f debian.Dockerfile .
docker build --no-cache -t xcmd/alpine:latest -f alpine.Dockerfile .

