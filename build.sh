#!/bin/bash
set -e

trap 'signal_handler SIGHUP' SIGHUP
trap 'signal_handler SIGINT' SIGINT

PRJ_DIR=$(realpath $(dirname "$0"))
RPM_SRCDIR=$PRJ_DIR/src/buildrpm
IMG_SRCDIR=$PRJ_DIR/src/buildimg

CURRENT_DIR=$(realpath $(pwd))
ARCH=$(uname -m)
REPO_FILE=""
WORK_DIR="$CURRENT_DIR/output"
PROFILE_TYPE="docker"
BUILD_TYPE="all"

source $RPM_SRCDIR/scripts/common.sh

function signal_handler()
{
   log_info "receive signal $1"
}

function usage()
{
    cat <<EOF
Usage: 
./$(basename $0) -a [aarch64|x86_64] -r [repo] -d [work dir] -p [live|virtual|disk|docker|devdocker] -t [rpm|image|all]
Attention!!!  you should use nohup to invoke compile, if you want background run it
EOF
}

function param_parse()
{
    while getopts "a:r:d:p:t:" opt
    do
        case "$opt" in
            a)
            ARCH="$OPTARG";;
            r)
            REPO_FILE="$OPTARG";;
            d)
            WORK_DIR="$OPTARG";;
            p)
            PROFILE_TYPE="$OPTARG";;
            t)
            BUILD_TYPE="$OPTARG";;
            ?)
            log_error "unknown parameters" && usage && return 1;;
        esac
    done

    [[ ! -n $ARCH ]] && log_error "empty parameter, -a" && usage && return 1
    [[ ! -n $REPO_FILE ]] && log_error "empty parameter, -r" && usage && return 1
    [[ ! -n $WORK_DIR ]] && log_error "empty parameter, -d" && usage && return 1
    [[ ! -n $PROFILE_TYPE ]] && log_error "empty parameter, -p" && usage && return 1
    [[ ! -n $BUILD_TYPE ]] && log_error "empty parameter, -t" && usage && return 1

    ( [[ $ARCH != "aarch64" ]] && [[ $ARCH != "x86_64" ]] ) && usage && return 1

    REPO_FILE=$(realpath $REPO_FILE)
    [[ ! -f $REPO_FILE ]] && log_error "repo file not exit" && usage && return 1

    WORK_DIR=$(realpath $WORK_DIR)
    [[ ! -d $WORK_DIR ]] && log_error "work directory not exit" && usage && return 1

    ( [[ $PROFILE_TYPE != "live" ]] && \
        [[ $PROFILE_TYPE != "virtual" ]] && \
        [[ $PROFILE_TYPE != "disk" ]] && \
        [[ $PROFILE_TYPE != "docker" ]] && \
        [[ $PROFILE_TYPE != "devdocker" ]] ) && \
        log_error "specified profile type not support" && usage && return 1

    ( [[ $BUILD_TYPE != "rpm" ]] && \
        [[ $BUILD_TYPE != "image" ]] && \
        [[ $BUILD_TYPE != "all" ]] ) && \
        log_error "specified build type not support" && usage && return 1

    return 0
}

function main()
{
    param_parse $@
    local repof=$REPO_FILE

    if [[ $BUILD_TYPE = "rpm" ]] || [[ $BUILD_TYPE = "all" ]]; then
        sh ${RPM_SRCDIR}/buildrpm.sh -a $ARCH -r $repof -d $WORK_DIR/
        [[ -d $WORK_DIR/baseroot ]] && rm -rf $WORK_DIR/baseroot
        [[ -d $WORK_DIR/tmp ]] && rm -rf $WORK_DIR/tmp
        local repof=$WORK_DIR/openeuler.repo
    fi

    if [[ $BUILD_TYPE = "image" ]] || [[ $BUILD_TYPE = "all" ]]; then
        sh -x ${IMG_SRCDIR}/buildimg.sh -a $ARCH -r $repof -d $WORK_DIR/ -p $PROFILE_TYPE
    fi
}

main $@
