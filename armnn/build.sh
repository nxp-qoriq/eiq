#!/bin/bash

# Copyright 2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Author: Yanan Yang <yanan.yang@nxp.com>
#

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH
DO_PRINT_HELP=false
INSTALL_DIR=/usr/local

# source code & git tree and branch
ARMCL_GIT="https://github.com/Arm-software/ComputeLibrary.git"
ARMCL_BRANCH="v19.02"
BOOST_URL="https://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.bz2"
STB_GIT="https://github.com/nothings/stb.git"
PROTOBUF_GIT="https://github.com/google/protobuf.git"
PROTOBUF_BRANCH="v3.5.0"
TENSORFLOW_GIT="https://github.com/tensorflow/tensorflow.git"
TENSORFLOW_BRANCH="v2.0.0-beta1"
FLATBUFFERS_GIT="https://github.com/google/flatbuffers.git"
FLATBUFFERS_BRANCH="1.11.0"
CAFFE_GIT="https://github.com/BVLC/caffe.git"
ONNX_GIT="https://github.com/onnx/onnx.git"
ARMNN_GIT="https://github.com/ARM-software/armnn.git"
ARMNN_BRANCH="v19.02"

function do_install_dependency() {
    apt-get install -y libleveldb-dev libsnappy-dev libhdf5-serial-dev #libopencv-dev
    apt-get install -y --no-install-recommends libboost-all-dev
    apt-get install -y libgflags-dev libgoogle-glog-dev liblmdb-dev
    apt-get install -y libopenblas-dev
    apt-get install -y libatlas-base-dev
    apt-get install -y cmake scons curl autoconf libtool build-essential
}

function do_compile_stb() {
    cd $BASEDIR
    if [ ! -d stb ]; then
        echo "clone std...$(pwd)"
        git clone $STB_GIT
    fi
}

function do_install_armcl() {
    CP_ARGS="-Prf --preserve=mode,timestamps --no-preserve=ownership"
    install -d $INSTALL_DIR/include

    cp $CP_ARGS arm_compute $INSTALL_DIR/include
    cp $CP_ARGS support $INSTALL_DIR/include
    cp $CP_ARGS include/half $INSTALL_DIR/include

    install -d $INSTALL_DIR/lib
    install -m 0755 build/libarm_compute*.so $INSTALL_DIR/lib

    install -d $INSTALL_DIR/bin
    for item in build/examples/*; do
        if [ -x $item ]; then
            install -m 0555 $item $INSTALL_DIR/bin
        fi
    done
}

function do_compile_armcl() {
    cd $BASEDIR
    if [ ! -d ComputeLibrary ]; then
        echo "clone ARM Compute Library..."
        git clone --branch $ARMCL_BRANCH $ARMCL_GIT
    fi
    if [ -d ComputeLibrary ]; then
        echo "building ARM Compute Library..."
        cd ComputeLibrary && \
            scons arch=arm64-v8a neon=1  extra_cxx_flags="-fPIC" \
            benchmark_tests=0 validation_tests=0 -j$JOBS
    fi
}

function do_compile_bootst() {
    cd $BASEDIR
    if [ ! -d boost_1_64_0 ]; then
        if [ ! -f boost_1_64_0.tar.bz2 ]; then
            wget $BOOST_URL
        fi
        tar -jxvf boost_1_64_0.tar.bz2
    fi
    if [ -d boost_1_64_0 ]; then
        cd boost_1_64_0 && \
        echo "using gcc : arm : aarch64-linux-gnu-g++ ;" > user_config.jam
        ./bootstrap.sh --prefix=$BASEDIR/armnn-devenv/boost_arm64_install
        ./b2 install toolset=gcc-arm link=static cxxflags=-fPIC \
            --with-filesystem --with-test --with-log \
            --with-program_options --user-config=user_config.jam -j$JOBS
    fi
}

function do_compile_protobuf() {
    cd $BASEDIR
    echo "protobuf build"
    if [ ! -d protobuf ]; then
        git clone --branch $PROTOBUF_BRANCH $PROTOBUF_GIT
        cd protobuf
        git submodule update --init --recursive
        cd ..
    fi
    if [ -d protobuf ]; then
        cd protobuf && \
        ./autogen.sh && \
        mkdir -p host_build && cd host_build && \
        ../configure --prefix=$BASEDIR/armnn-devenv/google/host_64_pb_install
        make install -j$JOBS
        cd ..

        mkdir -p arm64_build && cd arm64_build
        CC=aarch64-linux-gnu-gcc \
            CXX=aarch64-linux-gnu-g++ \
            ../configure --host=aarch64-linux \
            --prefix=$INSTALL_DIR \
            --with-protoc=$BASEDIR/armnn-devenv/google/host_64_pb_install/bin/protoc
        make install -j$JOBS
    fi
}

function do_compile_flatbuffer_host() {
    cd $BASEDIR
    if [ ! -d flatbuffers_host ]; then
        git clone --branch $FLATBUFFERS_BRANCH $FLATBUFFERS_GIT flatbuffers_host
    fi
    if [ -d flatbuffers_host ]; then
        cd flatbuffers_host && cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
            -DFLATBUFFERS_BUILD_SHAREDLIB=ON \
            -DFLATBUFFERS_BUILD_TESTS=OFF
        make -j$JOBS
    fi
}

function do_compile_flatbuffer() {
    cd $BASEDIR
    if [ ! -d flatbuffers ]; then
        git clone --branch $FLATBUFFERS_BRANCH $FLATBUFFERS_GIT
    fi
    if [ -d flatbuffers ]; then
        cd $BASEDIR/flatbuffers && \
        CXX=aarch64-linux-gnu-g++ CC=aarch64-linux-gnu-gcc \
        AR=aarch64-poky-linux-ar \
        AS=aarch64-poky-linux-as cmake -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_SO_NO_EXE=0 \
        -DFLATBUFFERS_BUILD_SHAREDLIB=ON \
        -DCMAKE_NO_SYSTEM_FROM_IMPORTED=1 \
        -DFLATBUFFERS_BUILD_TESTS=OFF \
        -DCMAKE_CXX_FLAGS=-fPIC \
        -DFLATBUFFERS_FLATC_EXECUTABLE=$BASEDIR/flatbuffers_host/flatc \
        && make -j$JOBS
    fi
}

function do_compile_caffe() {
    cd $BASEDIR
    if [ ! -d caffe ]; then
        #git clone -branch $CAFFE_BRANCH $CAFFE_GIT
        git clone $CAFFE_GIT
    fi
    if [ -d caffe ]; then
        cd caffe
        cp Makefile.config.example Makefile.config
        sed -i "/^# CPU_ONLY := 1/s/#//g" Makefile.config
        sed -i "/^# USE_OPENCV := 0/s/#//g" Makefile.config
        #sed -i "/^# OPENCV_VERSION/s/#//g" Makefile.config
        sed -i "/^INCLUDE_DIRS/a INCLUDE_DIRS += /usr/include/hdf5/serial/ $BASEDIR/armnn-devenv/google/host_64_pb_install/include/" Makefile.config
        sed -i "/^LIBRARY_DIRS/a LIBRARY_DIRS += /usr/lib/$(uname -i)-linux-gnu/hdf5/serial/ $BASEDIR/armnn-devenv/google/host_64_pb_install/lib/" Makefile.config
        export PATH=$BASEDIR/armnn-devenv/google/host_64_pb_install/bin/:$PATH
        export LD_LIBRARY_PATH=$BASEDIR/armnn-devenv/google/host_64_pb_install/lib/:$LD_LIBRARY_PATH
        make all -j$JOBS && make test -j$JOBS && make runtest -j$JOBS
   fi
}

function do_compile_onnx() {
    cd $BASEDIR
    if [ ! -d onnx ]; then
        export ONNX_ML=1
        git clone --recursive https://github.com/onnx/onnx.git
        unset ONNX_ML
    fi
    if [ -d onnx ]; then
        cd onnx
        export LD_LIBRARY_PATH=$BASEDIR/armnn-devenv/google/host_64_install/lib:$LD_LIBRARY_PATH
        $BASEDIR/armnn-devenv/google/host_64_pb_install/bin/protoc \
            onnx/onnx.proto --proto_path=. \
            --proto_path=$BASEDIR/armnn-devenv/google/host_64_pb_install/include \
            --cpp_out $BASEDIR/onnx
    fi
}

function do_compile_tensorflow_protobuf() {
    cd $BASEDIR
    if [ ! -d armnn ]; then
        git clone --branch $ARMNN_BRANCH $ARMNN_GIT
        cd armnn
        git am $SRCDIR/0001-stdlib-issue-work-around.patch
        #git am $SRCDIR/0002-enable-use-of-boost-shared-library.patch
        git am $SRCDIR/0003-add-more-test-command-line-arguments.patch
        git am $SRCDIR/0004-generate-versioned-library.patch
        git am $SRCDIR/0005-add-armnn-mobilenet-test-example.patch
        git am $SRCDIR/0006-armnn-mobilenet-test-example.patch
        git am $SRCDIR/0007-enable-use-of-arm-compute-shared-library.patch
    fi
    #4. download Tensorflow protobuf library
    cd $BASEDIR/
    if [ ! -d tensorflow ]; then
        git clone --branch $TENSORFLOW_BRANCH $TENSORFLOW_GIT
    fi
    if [ -d tensorflow ] && [ -d armnn ]; then
        cd tensorflow && \
        ../armnn/scripts/generate_tensorflow_protobuf.sh ../tensorflow-protobuf \
           $BASEDIR/armnn-devenv/google/host_64_pb_install/
    fi
}

function do_compile_armnn() {
    # build armnn
    cd $BASEDIR/
    if [ -d armnn ]; then
        cd armnn && mkdir -p build && cd build && \
            CXX=aarch64-linux-gnu-g++ \
            CC=aarch64-linux-gnu-gcc \
            cmake .. \
            -DBUILD_TESTS=1 \
            -DBUILD_UNIT_TESTS=1 \
            -DBUILD_SHARED_LIBS=ON \
            -DARMCOMPUTE_ROOT=$BASEDIR/ComputeLibrary \
            -DARMCOMPUTE_BUILD_DIR=$BASEDIR/ComputeLibrary/build/ \
            -DBOOST_ROOT=$BASEDIR/armnn-devenv/boost_arm64_install/ \
            -DTF_GENERATED_SOURCES=$BASEDIR/tensorflow-protobuf \
            -DPROTOBUF_ROOT=$INSTALL_DIR/ \
            -DBUILD_TF_LITE_PARSER=1 \
            -DTF_LITE_GENERATED_PATH=$BASEDIR/tensorflow/tensorflow/lite/schema \
            -DFLATBUFFERS_ROOT=$BASEDIR/flatbuffers \
            -DFLATBUFFERS_LIBRARY=$BASEDIR/flatbuffers/libflatbuffers.a \
            -DFLATC_DIR=$BASEDIR/flatbuffers_host \
            -DARMCOMPUTENEON=1  \
            -DBUILD_TF_PARSER=1 \
            -DCAFFE_GENERATED_SOURCES=$BASEDIR/caffe/build/src \
            -DBUILD_CAFFE_PARSER=1 \
            -DPROTOBUF_LIBRARY_DEBUG=$INSTALL_DIR/lib/libprotobuf.so.15.0.0 \
            -DPROTOBUF_LIBRARY_RELEASE=$INSTALL_DIR/lib/libprotobuf.so.15.0.0 \
            -DBUILD_ONNX_PARSER=1 \
            -DONNX_GENERATED_SOURCES=$BASEDIR/onnx \
            -DTHIRD_PARTY_INCLUDE_DIRS=$BASEDIR/stb \
            -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR
        make -j$JOBS && make install
        CP_ARGS="-Prf --preserve=mode,timestamps --no-preserve=ownership"
        if [ ! -d $INSTALL_DIR/bin ]; then
            mkdir -p $INSTALL_DIR/bin
        fi
        find $BASEDIR/armnn/build/tests -maxdepth 1 -type f -executable -exec cp $CP_ARGS {} $INSTALL_DIR/bin \;
        cp $CP_ARGS $BASEDIR/armnn/build/UnitTests  $INSTALL_DIR/bin
    fi
}

function do_cleanup() {
    echo "clean ...";
    if [ -d armnn_build ]; then
        rm -rf armnn_build
    fi
}

function do_build() {
    # work directory
    if [ ! -d armnn_build ]; then
        echo "mkdir armnn_build"
        mkdir -p armnn_build
    fi

    cd armnn_build
    BASEDIR=$(pwd)

    if [ ! -d $INSTALL_DIR ]; then
        mkdir -p $INSTALL_DIR
    fi

    do_compile_stb
    do_compile_armcl
    do_compile_bootst
    do_compile_protobuf
    do_compile_flatbuffer_host
    do_compile_flatbuffer
    do_compile_caffe
    do_compile_onnx
    do_compile_tensorflow_protobuf
    do_compile_armnn
}

function do_print_help() {
    echo "help info:
       -t [task]: set the parallel task number to build ArmNN
       -b: build ArmNN
       -d: set installation prefix
       -c: cleanup
       -h: print this info";
}

if ( $DO_INSTALL_DEPENDENCY ); then
    do_install_dependency
fi

if ( $DO_PRINT_HELP ); then
    do_print_help
    exit 0
fi
if ( $DO_CLEANUP ); then
    do_cleanup
fi
if ( $DO_BUILD ) || [ $# -eq 0 ] ; then
    echo "Start Build ArmNN ... "
    do_build
    echo "Done."
fi
