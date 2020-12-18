#!/bin/bash
#crude script to clean the containers. Not fool proof yet!
id=`docker ps --all | grep grassdev | cut -f1 -d" "`
docker container stop $id
docker container rm $id
id=`docker images | grep grassdev | cut -f1 -d" "`
docker image rm $id
