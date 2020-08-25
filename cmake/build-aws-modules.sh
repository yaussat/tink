#!/bin/bash
set -ex

# Build static libraries for kms and core modules of aws-cpp-sdk.
echo "Building aws-sdk"
CMAKE_BINARY_DIR=$1
AWS_SDK_VERSION=$2
cd ${CMAKE_BINARY_DIR}
wget https://github.com/aws/aws-sdk-cpp/archive/${AWS_SDK_VERSION}.tar.gz
tar -xvzf ${AWS_SDK_VERSION}.tar.gz
rm ${AWS_SDK_VERSION}.tar.gz
cd aws-sdk-cpp-${AWS_SDK_VERSION}
mkdir build && cd build
cmake .. \
    -DBUILD_ONLY=kms \
    -DSTATIC_LINKING=1 \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DENABLE_TESTING:BOOL=OFF \
    -DBUILD_DEPS=ON
make
