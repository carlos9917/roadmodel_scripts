#!/bin/bash
source env.sh
IMAGENAME=grassdev
CONTAINERNAME=grassrun # Name of the container based on IMAGENAME

#copy template and ask user to replace password
if [ -z $1 ]; then
  echo Please provide password for github repo
  exit
else
  gitpas=$1
fi

#Decide which template to use
if [ -z $2 ]; then
  dfile="dev"
else
  dfile=$2
fi
echo Using Dockerfile.temp.$dfile template

cp Dockerfile.temp.$dfile Dockerfile
cp ../../test_scripts/crontab .
cp ../../test_scripts/run-crond.sh .
chmod -v +x ./run-crond.sh

#Build the Image
#docker build -t $IMAGENAME .
docker build --build-arg PID=$PID --build-arg GID=$GID -t $IMAGENAME .
#docker build --user "$(id -u):$(id -g)" --build-arg PID=$PID --build-arg GID=$GID -t $IMAGENAME .

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
cp Dockerfile.temp.$dfile Dockerfile #so it doesnt save the one with the password
rm -f ./crontab
rm -f ./run-crond.sh
