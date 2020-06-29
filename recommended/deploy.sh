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
zip -r -q recommended-${VERSION}.zip .
mkdir -p ${BUILD_DIR}/dist/
mv recommended-${VERSION}.zip ${BUILD_DIR}/dist/
version_="${VERSION//\./_}"
aws lambda publish-layer-version \
    --layer-name r-recommended-${version_} \
    --zip-file fileb://${BUILD_DIR}/dist/recommended-${VERSION}.zip
