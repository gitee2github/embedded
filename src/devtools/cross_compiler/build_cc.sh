#!/bin/bash
set -e

GIT_URL="https://gitee.com/src-openeuler"
GIT_BRANCH="openEuler-20.03-LTS"
GIT_REPO_NAME=(gcc binutils glibc gmp libmpc mpfr kernel)

CURENT_DIR=$(realpath $(pwd))
BUILD_DIR=${CURENT_DIR}/build
SOURCE_DIR=${BUILD_DIR}/source

if [[ ${1} == "aarch64" ||  ${1} == "x86_64" ]];then
    ARCH=${1}
else
    echo "Usage: ./build.sh [aarch64|x86_64]"
    exit 1
fi

CROSS_COMPILER_DIR=${BUILD_DIR}/toolchains/${ARCH}_cross_compiler
CROSS_COMPILER_TARGET=${ARCH}-target-linux-gnu 

down_source(){
    for repo_name in ${GIT_REPO_NAME[*]}
    do
        git clone -b ${GIT_BRANCH} ${GIT_URL}/${repo_name} ${SOURCE_DIR}/${repo_name}
    done
    cd  ${SOURCE_DIR}/kernel
    git clone -b openEuler-1.0-LTS https://gitee.com/openeuler/kernel
    tar -czf kernel.tar.gz kernel
    cd -
}
prepare_env(){
    #install build tools
    dnf install -y make gawk gcc-c++ bison-devel m4 gmp-devel mpfr-devel libmpc-devel texinfo

    #rm -rf ${BUILD_DIR} && mkdir ${BUILD_DIR}
    rm -rf ${CROSS_COMPILER_DIR} && mkdir -p ${CROSS_COMPILER_DIR}

    down_source
    rpmbuild -bp --define "_sourcedir $SOURCE_DIR/gcc" --define "_builddir $BUILD_DIR"  ${SOURCE_DIR}/gcc/gcc.spec
    rpmbuild -bp --define "_sourcedir $SOURCE_DIR/gmp" --define "_builddir $BUILD_DIR" ${SOURCE_DIR}/gmp/gmp.spec
    rpmbuild -bp --define "_sourcedir $SOURCE_DIR/libmpc" --define "_builddir $BUILD_DIR" ${SOURCE_DIR}/libmpc/libmpc.spec
    rpmbuild -bp --define "_sourcedir $SOURCE_DIR/mpfr" --define "_builddir $BUILD_DIR" ${SOURCE_DIR}/mpfr/mpfr.spec
    rpmbuild -bp --define "_sourcedir $SOURCE_DIR/binutils" --define "_builddir $BUILD_DIR" ${SOURCE_DIR}/binutils/binutils.spec
    rpmbuild -bp --define "_sourcedir $SOURCE_DIR/kernel" --define "_builddir $BUILD_DIR" ${SOURCE_DIR}/kernel/kernel.spec
    rpmbuild -bp --define "_sourcedir $SOURCE_DIR/glibc" --define "_builddir $BUILD_DIR" ${SOURCE_DIR}/glibc/glibc.spec
}

build_binutils(){
    echo "Build binutils start..."
    mkdir -p  ${BUILD_DIR}/build-binutils
    cd ${BUILD_DIR}/build-binutils
    ../binutils-2.34/configure --prefix=${CROSS_COMPILER_DIR} --target=${CROSS_COMPILER_TARGET} --with-sysroot=${CROSS_COMPILER_DIR}/sysroot \
                               --enable-plugins --enable-ld=yes --enable-multilib --libdir=${CROSS_COMPILER_DIR} --enable-multilib 
    make -j4 LIB_PATH="=/usr/lib/:=/usr/lib64/:=/lib/:=/lib64:=/usr/local/lib:=/usr/local/lib64:=/usr/local/lib:=/usr/local/lib64\:=/usr/local/lib\
    :=/usr/local/lib64:=/usr/local/lib:=/usr/local/lib64:=/usr/local/lib:=/usr/local/lib64:=/usr/local/lib:=/usr/local/lib64:=/usr/local/lib\
    :=/usr/local/lib64:=/usr/local/lib:=/usr/local/lib64"
    
    make install
    cd -
    echo "Build binutils end..."
}


build_headers(){
    echo "Build kernel header start..."
    cd ${BUILD_DIR}/kernel-4.19.90/linux-4.19.90/
    if [ ${ARCH} == aarch64 ];then
        make ARCH=arm64 INSTALL_HDR_PATH=${CROSS_COMPILER_DIR}/${CROSS_COMPILER_TARGET} headers_install
    elif [ ${ARCH} == x86_64 ];then
        make ARCH=x86 INSTALL_HDR_PATH=${CROSS_COMPILER_DIR}/${CROSS_COMPILER_TARGET} headers_install
    fi
    cd -
    echo "Build kernel header end..."
}

build_gcc_compiler(){
    echo "Build gcc compiler start..."
    mkdir -p ${BUILD_DIR}/build-gcc
    cd ${BUILD_DIR}/build-gcc/
    ../gcc-7.3.0/configure --prefix=${CROSS_COMPILER_DIR} --target=${CROSS_COMPILER_TARGET} --enable-languages=c,c++ --disable-multilib \
                           --without-isl --without-cloog --with-gmp=/usr/ --with-mpc=/usr/ --with-mpfr=/usr/ \
                           --with-headers=${CROSS_COMPILER_DIR}/${CROSS_COMPILER_TARGET}/include/linux \
                           --with-gnu-as --with-gnu-ld --disable-libmudflap --enable-posion-system-directories \
                           --enable-symvers=gnu --enable-shared --enable-posion-system-directories 
    make -j4 all-gcc
    make install-gcc
    cd -
    echo "Build gcc compiler end..."
}

build_glibc_stage1(){
    echo "Build glibc stage1 start..."
    mkdir -p ${BUILD_DIR}/build-glibc
    cd ${BUILD_DIR}/build-glibc/
    ../glibc-2.28/configure --prefix=${CROSS_COMPILER_DIR}/${CROSS_COMPILER_TARGET} --build=$MACHTYPE --host=${CROSS_COMPILER_TARGET} \
                            --target=${CROSS_COMPILER_TARGET} --with-headers=${CROSS_COMPILER_DIR}/${CROSS_COMPILER_TARGET}/include \
                            --disable-multilib libc_cv_forced_unwind=yes libc_cv_fpie=no
    make install-bootstrap-headers=yes install-headers
    make -j4 csu/subdir_lib
    install csu/crt1.o csu/crti.o csu/crtn.o ${CROSS_COMPILER_DIR}/${CROSS_COMPILER_TARGET}/lib
    ${ARCH}-target-linux-gnu-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${CROSS_COMPILER_DIR}/${CROSS_COMPILER_TARGET}/lib/libc.so
    touch ${CROSS_COMPILER_DIR}/${CROSS_COMPILER_TARGET}/include/gnu/stubs.h
    cd -
    echo "Build glibc stage1 end..."
}

build_compiler_lib(){
    echo "Build compiler lib start..."
    cd ${BUILD_DIR}/build-gcc
    make -j4 all-target-libgcc
    make install-target-libgcc
    cd -
    echo "Build compiler lib end..."
}

build_glibc_stage2(){
    echo "Build glibc stage2 start..."
    cd ${BUILD_DIR}/build-glibc
    make -j4
    make install
    cd -
    echo "Build glibc stage2 end..."
}

build_c_plus(){
    echo "Build c plus start..."
    cd ${BUILD_DIR}/build-gcc/
    make -j4
    make install
    cd -
    echo "Build c plus end..."

}

pack_release(){
    #TODO pack to rpm packge
    tar -czf ${ARCH}_cross_compiler.tar.gz -C${BUILD_DIR}/toolchains/ ${ARCH}_cross_compiler
}

export PATH=${CROSS_COMPILER_DIR}/bin:$PATH
prepare_env
build_binutils
build_headers
build_gcc_compiler
build_glibc_stage1
build_compiler_lib
build_glibc_stage2
build_c_plus
pack_release