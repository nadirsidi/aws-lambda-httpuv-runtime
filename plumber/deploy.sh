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

# Try to save space!!!
rm -rf ./R/library/*/html
rm -rf ./R/library/*/doc
rm -rf ./R/library/*/NEWS.md
rm -rf ./R/library/*/help

zip -r -q plumber-${VERSION}.zip .
mkdir -p ${BUILD_DIR}/dist/
mv plumber-${VERSION}.zip ${BUILD_DIR}/dist/
version_="${VERSION//\./_}"
# aws lambda publish-layer-version \
#     --layer-name r-plumber-${version_} \
#     --zip-file fileb://${BUILD_DIR}/dist/plumber-${VERSION}.zip
