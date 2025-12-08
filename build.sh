#!/bin/bash
set -e

docker build --build-arg ALL_PROXY=http://172.23.128.1:10808 -t inventree-dockerbuild .

MSYS2_ARG_CONV_EXCL="*" docker run --rm \
  -e ALL_PROXY="http://172.23.128.1:10808" \
  -v "/d/github/inventree-mobile-app-apk-builder/output:/output" \
  inventree-dockerbuild
