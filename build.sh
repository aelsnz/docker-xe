#!/bin/bash
#
# Description:
# Use the command below to build the docker image with Oracle XE
#
docker build --shm-size 1024m -f dockerfiles/Dockerfile -t oracle-db:18cXE . 

