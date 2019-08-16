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
    apt-get install -y build-essential
    apt-get install -y wget zip unzip curl
}

function do_build() {
    # build tensorflow lite
    wget https://github.com/tensorflow/tensorflow/archive/v1.12.3.tar.gz
    tar xvf v1.12.3.tar.gz
    cd tensorflow-1.12.3
    patch -p1 < $BASE_DIR/0001-Add-build-script-for-aarch64.patch

    source tensorflow/contrib/lite/tools/make/download_dependencies.sh
    source tensorflow/contrib/lite/tools/make/build_aarch64_lib.sh
    cp tensorflow/contrib/lite/tools/make/gen/aarch64_armv8-a/lib/*.a /usr/local/lib
    cp tensorflow/contrib/lite/tools/make/gen/aarch64_armv8-a/bin/* /usr/local/bin
}

function do_cleanup() {
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
