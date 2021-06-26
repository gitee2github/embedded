#!/bin/sh
set -e

PRJ_DIR=$(realpath $(dirname "$0"))
KIWI_CONFIG=$(realpath "${PRJ_DIR}/../../config/kiwiconf")
SCRIPT_DIR="${PRJ_DIR}/script"

ARCH=$(uname -m)
REPO_FILE=""
WORK_DIR=""
PROFILE_TYPE="docker"

source "$SCRIPT_DIR"/util.sh
source "$SCRIPT_DIR"/make_image_kiwi.sh

function usage()
{
    cat <<EOF
Usage: 
./$(basename $0)
-a [aarch64|x86_64]
-r [repo]
-d [work dir]
-p [live|virtual|disk|docker]
EOF
}

function param_parse()
{
    while getopts "a:r:d:p:" opt
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
            ?)
            log_error "unknown parameters" && usage && return 1;;
        esac
    done

    [[ ! -n $ARCH ]] && log_error "empty parameter, -a" && usage && return 1
    [[ ! -n $REPO_FILE ]] && log_error "empty parameter, -r" && usage && return 1
    [[ ! -n $WORK_DIR ]] && log_error "empty parameter, -d" && usage && return 1
    [[ ! -n $PROFILE_TYPE ]] && log_error "empty parameter, -p" && usage && return 1

    ( [[ $ARCH != "aarch64" ]] && [[ $ARCH != "x86_64" ]] ) && usage && return 1

    REPO_FILE=$(realpath $REPO_FILE)
    [[ ! -f $REPO_FILE ]] && log_error "repo file not exit" && usage && return 1

    WORK_DIR=$(realpath $WORK_DIR)
    [[ ! -d $WORK_DIR ]] && log_error "work directory not exit" && usage && return 1

    ( [[ $PROFILE_TYPE != "live" ]] && \
        [[ $PROFILE_TYPE != "virtual" ]] && \
        [[ $PROFILE_TYPE != "disk" ]] && \
        [[ $PROFILE_TYPE != "docker" ]] ) && \
        log_error "specified profile type not support" && usage && return 1

    return 0
}

function main()
{
    param_parse $@
    make_image_kiwi
}

log_step "begin build image..."
main $@
log_step "build image done"

