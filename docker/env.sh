#!/bin/bash
#Set some environment variables for docker
echo Setting local paths and working directories
echo $WRKDIR
echo $SOURCE_DIR
export WRKDIR=$PWD
export SOURCE_DIR=$WRKDIR/src
export PID=$(id -u $USER)
export GID=$(id -g $USER)

alias docker_clean_images='docker rmi $(docker images -a --filter=dangling=true -q)'
alias brute_force_clean='docker rmi $(docker images -a)'
alias docker_clean_ps='docker rm $(docker ps --filter=status=exited --filter=status=created -q)'
