#!/bin/bash -e

# Copyright 2019 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Author: Feng Guo <feng.guo@nxp.com>
#

ARGS=`getopt -o h,j: -l "jobs:,with-tflite,with-tensorflow,with-opencv,help" -- "$@"`
eval set -- "${ARGS}"

BUILD_TFLITE=false
BUILD_TENSORFLOW=false
BUILD_OPENCV=false
JOBS=8

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
        -j|--jobs)
	    JOBS=$2
            shift 2
	    ;;
        -h|--help)
            echo "Usage: $0 [OPTION]"
            echo "Build the AI framework"
            echo ""
            echo "Options:"
            echo "   --with-tflite       build with tflite"
            echo "   --with-tensorflow   build with tensorflow"
            echo "   --with-opencv       build with opencv"
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

if ! ( $BUILD_TFLITE || $BUILD_TENSORFLOW || $BUILD_OPENCV ) ; then
    echo "$0: missing optstring argument"
    echo "Try '$0 --help' for more information."
    exit 1
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
