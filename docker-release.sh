#!/bin/sh

DOCKER_USERNAME="${DOCKER_USERNAME:-evildockertux}"


echo Release new hackmd version to docker!

echo Login to Docker Hub

if ! grep -q 'auths": {}' ~/.docker/config.json; then 
  docker login
else
  docker login -u $DOCKER_USERNAME
  if grep -q 'auths": {}' ~/.docker/config.json; then exit; fi
fi

echo [1/2] Create a new docker image.

docker build --rm --no-cache -t $DOCKER_USERNAME/hackmd .

echo [2/2] Push new docker image to docker hub.

docker push $DOCKER_USERNAME/hackmd

echo Finished!
