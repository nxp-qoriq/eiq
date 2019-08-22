#!/bin/bash

# Copyright 2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Author: Feng Guo <feng.guo@nxp.com>
#

BASE_DIR=`pwd`
echo "Start building in $BASE_DIR"

function do_install_dependency() {
    # install the dependencies
    apt-get install -y git zip unzip autoconf automake libtool curl zlib1g-dev maven swig bzip2
    apt-get install -y openjdk-8-jdk wget
    apt-get install -y python-numpy python-dev python-pip python-wheel python-h5py
    pip install enum34 mock keras_applications==1.0.8 keras_preprocessing==1.1.0
}

JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-arm64
JRE_HOME=${JAVA_HOME}/jre
CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
PATH=${JAVA_HOME}/bin:$PATH
GIT_SSL_NO_VERIFY=1

function do_build_protobuf() {
    # build proto buffer
    cd $BASE_DIR
    if [ ! -d protobuf-3.5.1 ]; then
        wget https://github.com/protocolbuffers/protobuf/archive/v3.5.1.zip
        unzip v3.5.1.zip
    fi

    cd protobuf-3.5.1
    ./autogen.sh
    ./configure --prefix=/usr/local
    make -j $JOBS
    make install
}

function do_build_bazel() {
    # build bazel
    cd $BASE_DIR
    if [ ! -d bazel ]; then
        mkdir bazel;cd bazel
        wget https://github.com/bazelbuild/bazel/releases/download/0.15.0/bazel-0.15.0-dist.zip
        unzip bazel-0.15.0-dist.zip
    else
        cd bazel
    fi

    ./compile.sh
    cp output/bazel /usr/bin/
}

function do_build_tensorflow() {
    # build tensorflow
    cd $BASE_DIR
    if [ ! -d tensorflow-1.12.3 ]; then
       wget https://github.com/tensorflow/tensorflow/archive/v1.12.3.tar.gz
       tar xvf v1.12.3.tar.gz
    fi

    cd tensorflow-1.12.3
    patch -p1 < $BASE_DIR/0001-Fix-aarch64-build-issue.patch
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
    bazel build --jobs=$JOBS --config=opt --verbose_failures //tensorflow/tools/pip_package:build_pip_package
    ./bazel-bin/tensorflow/tools/pip_package/build_pip_package ./target
    pip install ./target/tensorflow-1.12.3-cp27-cp27mu-linux_aarch64.whl
    mkdir -p /usr/share/tensorflow
    cp tensorflow/examples/label_image/label_image.py /usr/share/tensorflow
    cp tensorflow/examples/label_image/data/grace_hopper.jpg /usr/share/tensorflow
}

function do_build() {
    do_build_protobuf
    do_build_bazel
    do_build_tensorflow
}

function do_cleanup() {
    rm -rf protobuf-3.5.1
    rm -rf bazel
    rm -rf tensorflow-1.12.3
}

if ( $DO_INSTALL_DEPENDENCY ); then
    do_install_dependency
fi
if ( $DO_CLEANUP ); then
    do_cleanup
fi
if ( $DO_BUILD ) ; then
    do_build
fi
