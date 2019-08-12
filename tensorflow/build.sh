export http_proxy="http://wbi\nxf42681:Welcome%402017@apac.nics.nxp.com:8080"
export ftp_proxy="http://wbi\nxf42681:Welcome%402017@apac.nics.nxp.com:8080"
export https_proxy="http://wbi\nxf42681:Welcome%402017@apac.nics.nxp.com:8080"

BUILD_DIR=`pwd`
echo "Start building in $BUILD_DIR"

apt-get update
apt-get install -y git zip unzip autoconf automake libtool curl zlib1g-dev maven swig bzip2
apt-get install -y openjdk-8-jdk wget
apt-get install -y python-numpy python-dev python-pip python-wheel python-h5py
pip install enum34 mock keras_applications keras_preprocessing



JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-arm64
JRE_HOME=${JAVA_HOME}/jre
CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
PATH=${JAVA_HOME}/bin:$PATH
GIT_SSL_NO_VERIFY=1


git clone https://github.com/google/protobuf.git
cd protobuf
git checkout -b v3.5 origin/3.5.x
./autogen.sh
./configure --prefix=/usr/local
make -j4
make install

cd $BUILD_DIR

mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/0.15.0/bazel-0.15.0-dist.zip
unzip bazel-0.15.0-dist.zip
./compile.sh
cp output/bazel /usr/bin/

cd $BUILD_DIR

wget https://github.com/tensorflow/tensorflow/archive/v1.12.3.tar.gz
tar xvf v1.12.3.tar.gz
cd tensorflow-1.12.3
cp $BUILD_DIR/0001-Fix-aarch64-build-issue.patch .
patch -p1 < 0001-Fix-aarch64-build-issue.patch
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
bazel build --jobs=4 --config=opt --verbose_failures //tensorflow/tools/pip_package:build_pip_package
mkdir target
./bazel-bin/tensorflow/tools/pip_package/build_pip_package ./target
pip install ./target/tensorflow-1.12.3-cp27-cp27mu-linux_aarch64.whl
