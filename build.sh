#!/bin/bash

set -e

docker build --network=host . -t claude-container
