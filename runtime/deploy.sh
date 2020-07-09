#!/bin/bash

set -euo pipefail

if [[ -z ${1+x} ]];
then
    echo 'version number required'
    exit 1
else
    VERSION=$1
fi

BASE_DIR=$(pwd)
BUILD_DIR=${BASE_DIR}/build/

cd ${BUILD_DIR}/layer/
zip -r -q runtime-${VERSION}.zip .
mkdir -p ${BUILD_DIR}/dist/
mv runtime-${VERSION}.zip ${BUILD_DIR}/dist/
version_="${VERSION//\./_}"

aws --profile nadir-personal \
  --region us-east-2 \
  lambda publish-layer-version \
  --layer-name R-3_6_3-RookRuntime \
  --zip-file fileb://${BUILD_DIR}/dist/runtime-${VERSION}.zip
