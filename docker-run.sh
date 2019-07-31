#!/bin/bash

SELF_PATH=$(dirname $(readlink -f $0))
PROJECT_NAME=$(basename $SELF_PATH)
PROJECT_VERSION=`awk 'match($0, "VERSION = \"(.*)\"", m) { print m[1] }' version.php`

ENV=""

echo docker run $PROJECT_NAME v$PROJECT_VERSION

docker run --rm $ENV --name $PROJECT_NAME -p 127.0.0.1:3701:80 -t $PROJECT_NAME:v$PROJECT_VERSION
