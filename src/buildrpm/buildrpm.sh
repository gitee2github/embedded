#!/bin/bash
set -e

trap 'signal_handler SIGHUP' SIGHUP
trap 'signal_handler SIGINT' SIGINT

PRJ_DIR=$(realpath $(dirname "$0"))
SCRIPT_DIR=$PRJ_DIR/scripts
PATCH_DIR=$(realpath $PRJ_DIR/../patch)
CONFIG_DIR=$(realpath $PRJ_DIR/../../config)

CURRENT_DIR=$(realpath $(pwd))
WORKDIR=$CURRENT_DIR/output
REPO_DIR=$WORKDIR/rpms
BASEROOT_DIR=$WORKDIR/baseroot
RESULT_DIR=$WORKDIR/rpms
TMP_DIR=$WORKDIR/tmp
SRC_DIR=$WORKDIR/src

URL_FILE="$CONFIG_DIR/package_conf.xml"
AFTER_SCRIPT="$SCRIPT_DIR/baseroot_after.sh"

MAXJ=$(($(nproc --all) - 1))
ARCH=$(uname -m)
REPO_FILE=""
IMG_NAME="baseroot"
IMG_NAME_USER=0

PATH=$SCRIPT_DIR:$PATH
source $SCRIPT_DIR/common.sh

function signal_handler()
{
   log_info "receive signal $1"
}

function dedup_copy()
{
    local sdir=$(realpath $1)
    local destd=$(realpath $2)

    local all=$(find $sdir -name '*.rpm' | grep -E "rpmbuild/(SRPMS|RPMS)/($ARCH|noarch)" |xargs -n 1 rpm -qpi | grep -E 'Name[ ]+:' | cut -c 15-)
    for name in $all
    do
        rm -f  $destd/$name-[0-9]*.rpm
    done
    find $sdir -name '*.rpm' | xargs -n 1 -t -I sname cp sname $destd/
}

function usage()
{
    cat <<EOF
Usage: 
./$(basename $0) -a [aarch64|x86_64] -r [repo] -d [work dir] -j [max parallel] -t [image name]
Attention!!!  you should use nohup to invoke compile, if you want background run it
EOF
}

function param_parse()
{
    while getopts "a:r:d:j:t:" opt
    do
        case "$opt" in
            a)
            ARCH="$OPTARG";;
            r)
            REPO_FILE="$OPTARG";;
            d)
            WORKDIR="$OPTARG";;
            j)
            MAXJ="$OPTARG";;
            t)
            IMG_NAME="$OPTARG"; IMG_NAME_USER=1;;
            ?)
            log_error "unknown parameters" && usage && return 1;;
        esac
    done

    [[ ! -n $ARCH ]] && log_error "empty parameter, -a" && usage && return 1
    [[ ! -n $REPO_FILE ]] && log_error "empty parameter, -r" && usage && return 1
    [[ ! -n $WORKDIR ]] && log_error "empty parameter, -d" && usage && return 1
    [[ ! -n $MAXJ ]] && log_error "empty parameter, maxj" && usage && return 1
    [[ ! -n $IMG_NAME ]] && log_error "empty parameter, image name" && usage && return 1

    ( [[ $ARCH != "aarch64" ]] && [[ $ARCH != "x86_64" ]] ) && usage && return 1

    REPO_FILE=$(realpath $REPO_FILE)
    [[ ! -f $REPO_FILE ]] && log_error "repo file not exit" && usage && return 1

    WORKDIR=$(realpath $WORKDIR)
    REPO_DIR=$WORKDIR/rpms
    BASEROOT_DIR=$WORKDIR/baseroot
    RESULT_DIR=$WORKDIR/rpms
    TMP_DIR=$WORKDIR/tmp
    SRC_DIR=$WORKDIR/src

    [[ $MAXJ -lt 1 ]] && log_error "maxj[$MAXJ] error, it need great than 0" && return 1

    return 0
}

function directory_init()
{
    local clearflag=$1

    [[ $clearflag == 1 ]] && [[ -d $WORKDIR ]] && rm -rf $WORKDIR
    mkdir -p $WORKDIR

    [[ $clearflag == 1 ]] && [[ -d $REPO_DIR ]] && rm -rf $REPO_DIR
    mkdir -p $REPO_DIR

    [[ $clearflag == 1 ]] && [[ -d $BASEROOT_DIR ]] && rm -rf $BASEROOT_DIR
    mkdir -p $BASEROOT_DIR

    [[ $clearflag == 1 ]] && [[ -d $RESULT_DIR ]] && rm -rf $RESULT_DIR
    mkdir -p $RESULT_DIR

    [[ $clearflag == 1 ]] && [[ -d $TMP_DIR ]] && rm -rf $TMP_DIR
    mkdir -p $TMP_DIR

    [[ $clearflag == 1 ]] && [[ -d $SRC_DIR ]] && rm -rf $SRC_DIR
    mkdir -p $SRC_DIR
}

function main()
{
    param_parse $@
    directory_init 0

    log_info "MAXJ=$MAXJ"

    local allsrclist=$WORKDIR/allsrcpath.list
    log_step "download and patch source"
    loadsource -c $URL_FILE -d $SRC_DIR -p -l $allsrclist

    local tmprepof=$WORKDIR/$(basename $REPO_FILE)
    cp $REPO_FILE $tmprepof

    for cnt in 1 2
    do
        if [[ x$IMG_NAME_USER == x"0" ]]; then
            log_step "[$cnt]create base root"
            rm -rf $BASEROOT_DIR/*
            docker rmi $IMG_NAME || log_info "no need rmi history $IMG_NAME"
            makerootfs dockerimage -a $ARCH -r $tmprepof -d $BASEROOT_DIR -t $IMG_NAME -s $AFTER_SCRIPT
        fi
        IMG_NAME_USER=0

        log_step "[$cnt]build packge specified by [$allsrclist]"
        buildallrpmsfordocker -a $ARCH -r $tmprepof -d $TMP_DIR -j $MAXJ -t $IMG_NAME -l $allsrclist

        pushd $TMP_DIR/
            local logf=$WORKDIR/logs_${cnt}.tar.gz
            [[ -f $logf ]] && rm -f $logf
            log_step "[$cnt]save package build log to [$logf]"
            tar -czf $logf logs/
        popd

        log_step "[$cnt]remove BUILD path and copy rpm/srpm to repo directory"
        find $TMP_DIR -name BUILD -type d | grep 'rpmbuild/BUILD$' | xargs -n 1 rm -rf
        dedup_copy $TMP_DIR $REPO_DIR

        log_step "[$cnt]init repo"
        createrepodata init -d $REPO_DIR || log_info "update local repo not success"

        if [[ $cnt = 1 ]]; then
            log_step "[$cnt]add more repo to $tmprepof"
            addrepository addtop -r $tmprepof -s $REPO_DIR -n test -p 1
        fi

        rm $TMP_DIR/* -rf
    done
}

log_step "begin building..."
main $@
log_step "build done"

