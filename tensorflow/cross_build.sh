#!/bin/bash -e

# Copyright 2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Author: Feng Guo <feng.guo@nxp.com>
#

BUILD_DIR=`pwd`
echo "Start building in $BUILD_DIR"
JOBS=16
# install the dependencies
apt-get update
apt-get install -y git zip unzip autoconf automake libtool curl zlib1g-dev maven swig bzip2
apt-get install -y openjdk-8-jdk wget
apt-get install -y gcc-aarch64-linux-gnu=4:7.4.0-1ubuntu2.3 g++-aarch64-linux-gnu=4:7.4.0-1ubuntu2.3
apt-get install -y python-numpy python-dev python-pip python-wheel python-h5py
pip install enum34 mock keras_applications==1.0.8 keras_preprocessing==1.1.0


mkdir -p /usr/aarch64-linux-gnu/include/aarch64-linux-gnu/python2.7
cp $BUILD_DIR/pyconfig.h /usr/aarch64-linux-gnu/include/aarch64-linux-gnu/python2.7

JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-arm64
JRE_HOME=${JAVA_HOME}/jre
CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
PATH=${JAVA_HOME}/bin:$PATH
GIT_SSL_NO_VERIFY=1

# build proto buffer
cd $BUILD_DIR
wget https://github.com/protocolbuffers/protobuf/archive/v3.5.1.zip
unzip v3.5.1.zip
cd protobuf-3.5.1
./autogen.sh
./configure --prefix=/usr/local
make -j $JOBS
make install

# build bazel
cd $BUILD_DIR
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/0.15.0/bazel-0.15.0-dist.zip
unzip bazel-0.15.0-dist.zip
./compile.sh
cp output/bazel /usr/bin/

# build tensorflow
cd $BUILD_DIR
wget https://github.com/tensorflow/tensorflow/archive/v1.12.3.tar.gz
tar xvf v1.12.3.tar.gz
cd tensorflow-1.12.3
cp $BUILD_DIR/0001-Fix-aarch64-build-issue.patch .
cp $BUILD_DIR/0001-Add-cross-build-script-for-aarch64.patch .
patch -p1 < 0001-Fix-aarch64-build-issue.patch
patch -p1 < 0001-Add-cross-build-script-for-aarch64.patch
export CC_OPT_FLAGS="-march=native"
export PYTHON_BIN_PATH="/usr/bin/python"
export USE_DEFAULT_PYTHON_LIB_PATH=1
export TF_NEED_IGNITE=0
export TF_ENABLE_XLA=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_ROCM=0
export TF_NEED_CUDA=0
export TF_DOWNLOAD_CLANG=0
export TF_NEED_MPI=0
export TF_SET_ANDROID_WORKSPACE=0
./configure
#bazel build --jobs=$JOBS --config=opt --verbose_failures //tensorflow/tools/pip_package:build_pip_package
bazel build -c opt  //tensorflow/tools/pip_package:build_pip_package --cpu=aarch64 --crosstool_top=//tools/aarch64_compiler:toolchain --host_crosstool_top=@bazel_tools//tools/cpp:toolchain --verbose_failures
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ./target --plat_name linux_aarch64
cp ./target/tensorflow-1.12.3-cp27-cp27mu-linux_aarch64.whl $BUILD_DIR
cd $BUILD_DIR
