#!/bin/bash

ARGS=`getopt -o h -l "with-tflite,with-tensorflow,with-opencv,help" -- "$@"`
eval set -- "${ARGS}"

BUILD_TFLITE=false
BUILD_TENSORFLOW=false
BUILD_OPENCV=false

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
        -h|--help)
            echo "Usage: eiq_builder.sh [OPTION]"
            echo "Build the AI framework"
            echo ""
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
            echo "Internal error!"
            exit 1
            ;;
    esac
done

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
