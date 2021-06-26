#!/bin/bash

function log_error()
{
    echo [ERROR]$@
}

function log_info()
{
    echo [INFO]$@
}

function log_step()
{
    echo [STEP][$(date +'%Y-%m-%d %H:%M:%S')]$@
}

function keylist_init()
{
    local file=$(realpath $1)

    [[ ! -d $(dirname $file) ]] && log_info "dir not exist" && return 1
    [[ -f $file ]] && rm -f $file
    touch $file
}

function keylist_add()
{
    local file=$(realpath $1)
    local key=$2
    local val=$3

    echo "$key $val" >> $file
}

function keylist_read()
{
    local file=$(realpath $1)
    local indexway=$2
    local key=$3

    if [[ x$indexway = x"num" ]]; then
        cat $file | grep '\S' | sed -n ${key}p
    elif [[ x$indexway = x"key" ]]; then
        cat $file | grep '\S' | grep ^$key
    fi
}

function keylist_cnt()
{
    local file=$(realpath $1)

    cat $file | grep '\S' | wc -l
}

function keylist_read_key()
{
    keylist_read "$1" "$2" "$3"  | cut -d ' ' -f 1
}

function keylist_read_val()
{
    keylist_read "$1" "$2" "$3"  | cut -d ' ' -f 2
}

