#!/bin/bash
# Run oml2bikeshed in docker container
# Usage: oml2bsdocker <intputfolder> <outputfolder> [URL]
export IMAGE=oml2bikeshed
if [ "$3" = "" ]; then
  docker run $IMAGE -v $1:/input -v $2:/output
else
  docker run $IMAGE -v $1:/input -v $2:/output -e URL=$3
fi
