#!/bin/sh

echo Release new hackmd version to docker!

echo [1/2] Create a new docker image.

docker build --no-cache -t evildockertux/hackmd .

echo [2/2] Push new docker image to docker hub.

docker push evildockertux/hackmd

echo Finished!
