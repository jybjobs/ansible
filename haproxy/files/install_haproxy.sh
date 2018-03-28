#!/bin/bash

var_manageKey=$1
var_soft_download=$2
var_mode=$3
var_keep_version=$4
var_ps=$5
var_vip=$6
var_localip=$7

exec 1> /root/info.log
exec 2> /root/install.log

source /tmp/func.sh

function haproxy_single()
{
con_manage_key "${var_manageKey}"
which haproxy
if [ $? -ne 0 ]; then
build_in_haproxy ${var_soft_download}
fi
}

function haproxy_cluster()
{
con_manage_key "${var_manageKey}"

which haproxy
if [ $? -ne 0 ]; then
build_in_haproxy ${var_soft_download}
fi

which keepalived
if [ $? -ne 0 ]; then
build_in_keep ${var_soft_download} ${var_keep_version}
fi

config_keep ${var_ps} ${var_vip} ${var_localip}
}

haproxy_${var_mode}
fn_log "haproxy_${var_mode}"

log_info '-----Success000 !!!-----'
