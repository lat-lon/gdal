#!/bin/sh
# This file is available at the option of the licensee under:
# Public domain
# or licensed under MIT (LICENSE.TXT) Copyright 2019 Even Rouault <even.rouault@spatialys.com>

set -eu

SCRIPT_DIR=$(dirname "$0")
case $SCRIPT_DIR in
    "/"*)
        ;;
    ".")
        SCRIPT_DIR=$(pwd)
        ;;
    *)
        SCRIPT_DIR=$(pwd)/$(dirname "$0")
        ;;
esac

export SCRIPT_DIR
TAG_NAME=$(basename "${SCRIPT_DIR}")
export TARGET_IMAGE=${TARGET_IMAGE:-lat-lon/gdal:${TAG_NAME}}

HAS_PLATFORM=0
if echo "$*" | grep "\-\-platform" > /dev/null; then
  HAS_PLATFORM=1
fi

HAS_RELEASE=0
if echo "$*" | grep "\-\-release" > /dev/null; then
  HAS_RELEASE=1
fi

HAS_PUSH=0
if echo "$*" | grep "\-\-push" > /dev/null; then
  HAS_PUSH=1
fi

"${SCRIPT_DIR}/../util.sh" "$@" --test-python

if test "${HAS_PLATFORM}" = "0" -a "${HAS_RELEASE}" = "0" -a "x${TARGET_IMAGE}" = "xlat-lon/gdal:ubuntu-full"; then
 "${SCRIPT_DIR}/../util.sh" --platform linux/arm64 "$@" --test-python

 if test "$HAS_PUSH" = "1"; then
   docker manifest rm ${TARGET_IMAGE}-latest || /bin/true
   docker manifest create ${TARGET_IMAGE}-latest \
     --amend ${TARGET_IMAGE}-latest-amd64 \
     --amend ${TARGET_IMAGE}-latest-arm64
   docker manifest push ${TARGET_IMAGE}-latest

   docker manifest rm lat-lon/gdal || /bin/true
   docker manifest create lat-lon/gdal \
     --amend lat-lon/gdal:ubuntu-full-latest-amd64 \
     --amend lat-lon/gdal:ubuntu-full-latest-arm64
   docker manifest push lat-lon/gdal
 fi
fi
