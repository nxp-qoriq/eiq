#!/bin/bash -e

# Copyright 2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Author: Feng Guo <feng.guo@nxp.com>
#

BUILD_DIR=`pwd`
TARGET_DIR="$BUILD_DIR/target"
echo "Start building in $BUILD_DIR"

# install the dependencies
echo "deb [arch=arm64] http://us.ports.ubuntu.com/ubuntu-ports/ bionic main" >> /etc/apt/sources.list
echo "deb [arch=arm64] http://us.ports.ubuntu.com/ubuntu-ports/ bionic-updates main" >> /etc/apt/sources.list
echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports bionic-security main" >> /etc/apt/sources.list
echo "deb [arch=arm64] http://us.ports.ubuntu.com/ubuntu-ports/ bionic universe" >> /etc/apt/sources.list
echo "deb [arch=arm64] http://us.ports.ubuntu.com/ubuntu-ports/ bionic-updates universe" >> /etc/apt/sources.list
echo "deb [arch=arm64] http://us.ports.ubuntu.com/ubuntu-ports/ bionic multiverse" >> /etc/apt/sources.list
echo "deb [arch=arm64] http://us.ports.ubuntu.com/ubuntu-ports/ bionic-updates multiverse" >> /etc/apt/sources.list

apt-get update
apt-get install -y gcc-aarch64-linux-gnu=4:7.4.0-1ubuntu2.3
apt-get install -y g++-aarch64-linux-gnu=4:7.4.0-1ubuntu2.3
apt-get install -y wget zip unzip curl patch build-essential

dpkg --add-architecture arm64
apt-get install -y zlib1g-dev:arm64=1:1.2.11.dfsg-0ubuntu2

# build tensorflow lite
wget https://github.com/tensorflow/tensorflow/archive/v1.12.3.tar.gz
tar xvf v1.12.3.tar.gz
cd tensorflow-1.12.3
cp $BUILD_DIR/0001-Add-build-script-for-aarch64.patch .
patch -p1 < 0001-Add-build-script-for-aarch64.patch

source tensorflow/contrib/lite/tools/make/download_dependencies.sh
source tensorflow/contrib/lite/tools/make/build_aarch64_lib.sh
mkdir -p $TARGET_DIR/usr/local/lib
mkdir -p $TARGET_DIR/usr/local/bin
cp tensorflow/contrib/lite/tools/make/gen/aarch64_armv8-a/lib/*.a $TARGET_DIR/usr/local/lib
cp tensorflow/contrib/lite/tools/make/gen/aarch64_armv8-a/bin/* $TARGET_DIR/usr/local/bin
