#!/bin/bash

# Copyright 2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Author: Barry Cao <barry.cao@nxp.com>
#


function do_install_dependency() {
    # install the dependencies
    apt-get install -y libgtk2.0-dev pkg-config cmake python-dev python
}

function do_build() {
    # git clone opencv source code
    if [ ! -d stb ]; then
        git clone https://source.codeaurora.org/external/imx/opencv-imx
        cd ./opencv-imx
        git branch -a
        git checkout -b 4.0.1_imx remotes/origin/4.0.1_imx
    else
        cd ./opencv-imx
    fi

    # start compile configure
    mkdir build;cd build
    mkdir install
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_opencv_python2=ON  \
        -DINSTALL_PYTHON_EXAMPLES=ON \
        -DBUILD_opencv_python3=OFF \
        -DWITH_GTK=ON  \
        -DWITH_GTK_2_X=ON  \
        -DWITH_OPENCL=OFF  \
        -DBUILD_JASPER=ON  \
        -DINSTALL_TESTS=ON  \
        -DBUILD_EXAMPLES=ON \
        -DBUILD_opencv_apps=ON \
        -DCMAKE_INSTALL_PREFIX=/usr/local

    # start compile
    make -j $JOBS

    # install
    make install
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
