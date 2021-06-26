#!/bin/bash

function log_info()
{
    echo "[INFO] $*"
}

function log_error()
{
    echo "[ERROR] $*"
}

function log_step()
{
    echo "[STEP][$(date +'%Y-%m-%d %H:%M:%S')] $*"
}
