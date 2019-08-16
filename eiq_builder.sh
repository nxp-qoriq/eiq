#!/bin/bash -e

# Copyright 2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Author: Feng Guo <feng.guo@nxp.com>
#
set -euo pipefail

ARGS=`getopt -o c,h,j: -l "clean,jobs:,with-tflite,with-tensorflow,
                           with-opencv,with-armnn,skip-dependency,help" -- "$@"`
eval set -- "${ARGS}"

BUILD_TFLITE=false
BUILD_TENSORFLOW=false
BUILD_OPENCV=false
BUILD_ARMNN=false
JOBS=8
DO_CLEANUP=false
DO_BUILD=true
DO_INSTALL_DEPENDENCY=true

while true;
do
    case "$1" in
        --with-tflite)
            echo "build with tflite"
            BUILD_TFLITE=true
            shift 1
            ;;
        --with-tensorflow)
            echo "build with tensorflow"
            BUILD_TENSORFLOW=true
            shift 1
            ;;
        --with-opencv)
            echo "build with opencv"
            BUILD_OPENCV=true
            shift 1
            ;;
        --with-armnn)
            echo "build with armnn"
            BUILD_ARMNN=true
            shift 1
            ;;
        -j|--jobs)
            JOBS=$2
            shift 2
            ;;
        -c|--clean)
            DO_CLEANUP=true
            shift 1
            ;;
        --skip-dependency)
            DO_INSTALL_DEPENDENCY=false
            shift 1
            ;;
        -h|--help)
            echo "Usage: $0 [OPTION]"
            echo "Build the AI framework"
            echo ""
            echo "Options:"
            echo "   --with-tflite       build with tflite"
            echo "   --with-tensorflow   build with tensorflow"
            echo "   --with-opencv       build with opencv"
            echo "   --skip-dependency   do not install dependency before building"
            echo "-c --clean             cleanup build env before building"
            echo ""
            echo "-h --help    display this help and exit"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "unrecognized option $1!"
            exit 1
            ;;
    esac
done

if ! ( $BUILD_TFLITE || $BUILD_TENSORFLOW || $BUILD_OPENCV || $BUILD_ARMNN) ; then
    echo "$0: please select one or more framework(s) to build"
    echo "Try '$0 --help' for more information."
    exit 1
fi

if ( $DO_INSTALL_DEPENDENCY ); then
    apt-get update
fi

TOP=`pwd`
if ( $BUILD_TFLITE ); then
    echo "Start building tflite"
    cd tflite
    source build.sh
    cd $TOP
fi
if ( $BUILD_TENSORFLOW ); then
    echo "Start building tensorflow"
    cd tensorflow
    source build.sh
    cd $TOP
fi
if ( $BUILD_OPENCV ); then
    echo "Start building opencv"
    cd opencv
    source build.sh
    cd $TOP
fi
if ( $BUILD_ARMNN ); then
    echo "Start building opencv"
    cd armnn
    source build.sh
    cd $TOP
fi
