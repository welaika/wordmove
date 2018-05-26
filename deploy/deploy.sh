#! /usr/bin/env bash

curl -H "Content-Type: application/json" --data '{"docker_tag": "latest"}' -X POST "$DOCKER_TRIGGER"
