#!/bin/bash
#Deploy the container, either production or development

source env.sh
IMAGENAME=grassdev
CONTAINERNAME=grassrun # Name of the container based on IMAGENAME
build=1 #default: only build

if [ -z $1 ] && [ -z $2 ]; then
  echo "Please provide which template to use (dev or prod) and build/run "
  echo "Example: dev 1 (1 for build only, 2 for build and run)"
  exit
else
  dfile=$1 #dev or prod
  build=$2 #1 for build only, 2 for build and run
fi

echo Using Dockerfile.temp.$dfile template
[ ! -f ./Dockerfile.temp.$dfile ] && echo "ERROR: $dtype unknown"
cp Dockerfile.temp.$dfile Dockerfile

#Build the Image
docker build --build-arg PID=$PID --build-arg GID=$GID -t $IMAGENAME .

if [ $build == 2 ]; then
  #Stop any previous containers with this name before running
  if [ ! "$(docker ps -q -f name=$CONTAINERNAME)" ]; then
      if [ "$(docker ps -aq -f status=exited -f name=$CONTAINERNAME)" ]; then
          # cleanup
          echo "Removing container $CONTAINERNAME"
          docker rm $CONTAINERNAME
      fi
  else
      docker stop $CONTAINERNAME
      docker rm $CONTAINERNAME
  fi
  
  
  # create directory container-data if not present. If I don't create before,
  # it will be owned by root!
  #Run the image in container
  [ -d $WRKDIR/container-data ] || mkdir -p $WRKDIR/container-data
  docker run -dit -P --name $CONTAINERNAME -v $WRKDIR/container-data:/data $IMAGENAME
  
  #Send STDOUT from container
  docker logs -f $CONTAINERNAME > docker.log
else
  echo Only building container. Select 2 for running
fi
