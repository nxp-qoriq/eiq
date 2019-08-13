#!/bin/bash -e

# Copyright 2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Author: Feng Guo <feng.guo@nxp.com>
#

BUILD_DIR=`pwd`
echo "Start building in $BUILD_DIR"

# install the dependencies
apt-get update
apt-get install -y build-essential

# build tensorflow lite
wget https://github.com/tensorflow/tensorflow/archive/v1.12.3.tar.gz
tar xvf v1.12.3.tar.gz
cd tensorflow-1.12.3
cp $BUILD_DIR/0001-Add-build-script-for-aarch64.patch .
patch -p1 < 0001-Add-build-script-for-aarch64.patch

source tensorflow/contrib/lite/tools/make/download_dependencies.sh
source tensorflow/contrib/lite/tools/make/build_aarch64_lib.sh
cp tensorflow/contrib/lite/tools/make/gen/aarch64_armv8-a/lib/*.a /usr/local/lib
cp tensorflow/contrib/lite/tools/make/gen/aarch64_armv8-a/bin/* /usr/local/bin
