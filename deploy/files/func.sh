#!/bin/bash

log_file="/root/install.log"

function log_info ()
{
  ddate=`date "+%Y-%m-%d %H:%M:%S"`
  echo "${ddate} [info] $@" >> ${log_file}
}

function log_error ()
{
  ddate=`date "+%Y-%m-%d %H:%M:%S"`
  echo "${ddate} [error] Error000 !!! $@" >> ${log_file}
}

function fn_log ()
{
  if [  $? -eq 0  ]
    then
      log_info "$@"
  else
    log_error "$@ failed."
    exit 1
  fi
}

function con_manage_key()
{
  #添加密钥管理
  var_manageKey=$1

  if [ "${var_manageKey}" == "default" ]; then
    echo "managekey is default"
  else
    echo "${var_manageKey}" >> ~/.ssh/a
    cat ~/.ssh/a >> /root/.ssh/authorized_keys
  fi
}

#lvm operation
function fn_mk_fs ()
{
 var_mount_dir=$1
 var_mount_type=$2
 var_opt_disk=""

while :
   do
        var_disk=`fdisk -l |grep /dev/[v,s,h]|awk -F [\ :] '{if($1~ "Disk"){print $2} else {print $1}}'|sed 's/[0-9]*$//g'|sort |uniq -u|sort -r|head -1`
        fn_log "var_disk:${var_disk}"
        if  [ "${var_disk}"  == "" ] ; then
            log_info "enter sleep 5"
            sleep 5
            continue
        else
            var_opt_disk=${var_disk}
            break
        fi
    done

log_info "var_opt_disk:${var_opt_disk}"

pvcreate ${var_opt_disk}
fn_log "pvcreate ${var_opt_disk}"

vgcreate datavg ${var_opt_disk}
fn_log "vgcreate datavg ${var_opt_disk}"

lvcreate -l 100%FREE -n lvData datavg
fn_log "lvcreate -l 100%FREE -n lvData datavg"

mkfs -t ${var_mount_type} /dev/datavg/lvData
fn_log "mkfs -t ${var_mount_type} /dev/datavg/lvData"

mkdir -p ${var_mount_dir} 

mount /dev/datavg/lvData ${var_mount_dir} 
fn_log "mount /dev/datavg/lvData ${var_muont_dir}"

echo "/dev/datavg/lvData ${var_mount_dir} ${var_mount_type} defaults 0 0">>/etc/fstab

}
## vsan disk mount

function fn_nfs ()
{
while :
   do
        var_disk=`fdisk -l |grep /dev/[v,s,h]|awk -F [\ :] '{if($1~ "Disk"){print $2} else {print $1}}'|sed 's/[0-9]*$//g'|sort |uniq -u|sort -r|head -1`
        fn_log "var_disk:${var_disk}"
        if  [ "${var_disk}"  == "" ] ; then
            log_info "enter sleep 5"
            sleep 5
            continue
        else
            var_opt_disk=${var_disk}
            break
        fi
    done

log_info "var_opt_disk:${var_opt_disk}"

pvcreate ${var_opt_disk}
fn_log "pvcreate ${var_opt_disk}"

vgcreate nfs ${var_opt_disk}
fn_log "vgcreate nfs ${var_opt_disk}"

}


#modify yum config
function fn_yum_conf()
{
  var_yum_download=${1}
  if [ -n "${var_soft_download}" ]; then
    #rm -f /etc/yum.repos.d/CentOS-Base.rep
    #curl ${var_soft_download}/help/CentOS-Base.repo > /etc/yum.repos.d/CentOS-Base.repo
    #fn_log "curl ${var_soft_download}/help/CentOS-Base.repo > /etc/yum.repos.d/CentOS-Base.repo"
    #sed -i "s#http://linux-mirror#${var_soft_download}#g"  /etc/yum.repos.d/CentOS-Base.repo
    #yum clean all
    #fn_log "yum clean all"
    rm -rf /etc/yum.repos.d/*
    echo "
[res]
name=Openbridge RES 
baseurl=${var_soft_download}
enabled=1
gpgcheck=0
priority=1
" > /etc/yum.repos.d/res.repo
  fi
 yum install wget unzip -y
}

function build_in_keep()
{
  var_soft_download=${1}
  var_keep_version=${2}
  #安装keepalived
  log_info "-----build in keepalived begin-----"
  yum install -y openssl-devel popt-devel
  wget -P /opt ${var_soft_download}/keepalived/keepalived-bin-${var_keep_version}.tar.gz
  #wget -P /opt ${var_soft_download}/mysql/downloads/tools/keepalived-${var_keep_version}.tar.gz
  tar -zxvf /opt/keepalived-bin-${var_keep_version}.tar.gz -C /opt
  #cd /opt/keepalived-${var_keep_version}
  #./configure --prefix=/usr/local/keepalived
  #make && make install
  cp /opt/keepalived/sbin/keepalived /usr/sbin/
  cp /opt/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
  cp /opt/keepalived/etc/rc.d/init.d/keepalived /etc/init.d/
  cd /etc/init.d/
  chkconfig --add keepalived
  chkconfig keepalived on
  mkdir -p /etc/keepalived
  echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
  echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
  log_info "-----build in keepalived end-----"
}

function get_ip() {

    local IPS=(`ip addr show | grep inet | grep -v inet6 | grep brd | awk '{print $2}' | cut -f1 -d '/'`)

    if [ "${IPS[0]}" == "" ]; then
        echo "[ERROR] get ip address error"
	exit 1
    else
       echo ${IPS[0]}
    fi
}

function config_keep()
{
  #配置keepalived
  var_ps=${1}
  var_vip=${2}
  var_localip=${3}
  log_info "-----config keepalived begin-----"
  var_route_id=`echo ${var_vip}|awk -F"." '{print $4}'`
  var_server_ip_net=`ip a |grep -B2 ${var_localip}|head -1|awk -F':' '{print $2}'`
echo "
! Configuration File for keepalived
global_defs {
router_id ka_app_1
}
vrrp_script chk_app {
script "/etc/keepalived/check_app.sh"
interval 15
weight 2
}
vrrp_instance VI_KA_1 {
state BACKUP
nopreempt
interface ${var_server_ip_net}
virtual_router_id ${var_route_id}
priority ${var_ps}
advert_int 5
authentication {
    auth_type PASS
    auth_pass 1111
}
track_script {
    chk_app
}
virtual_ipaddress {
    ${var_vip} #vip
}
}
" > /etc/keepalived/keepalived.conf

echo "
#!/bin/bash

if [ 'ps -C haproxy --no-header |wc -l' -eq 0 ]; then
  /usr/local/haproxy/sbin/haproxy -f /usr/local/haproxy/conf/haproxy.cfg
  sleep 3
if [ 'ps -C haproxy --no-header |wc -l' -eq 0 ]; then
  /etc/init.d/keepalived stop
fi
fi
" > /etc/keepalived/check_app.sh

  sed -i -e "s%'%\`%g" /etc/keepalived/check_app.sh

  service keepalived start
  if [ $? -eq 0 ]; then
    log_info "keepalived success"
  else
    exit 1
  fi

  log_info "-----config keepalived end-----"
}

function build_in_haproxy()
{
  var_soft_download=${1}
  # install haproxy
  log_info "-----install haproxy begin-----"
  #yum install -y gcc
  echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
  echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
  sysctl -p /etc/sysctl.conf
  groupadd haproxy
  useradd -g haproxy haproxy -s /bin/false
  wget -P /opt ${var_soft_download}/haproxy/haproxy-bin-1.7.1.tar.gz
  fn_log "wget -P /opt ${var_soft_download}/haproxy/haproxy-bin-1.7.1.tar.gz"
  tar -zxvf /opt/haproxy-bin-1.7.1.tar.gz -C /usr/local/
  fn_log "tar -zxvf /opt/haproxy-1.7.1.tar.gz -C /usr/local"
  #cd /opt/haproxy-1.7.1
  #make TARGET=linux2628 PREFIX=/usr/local/haproxy
  #make install PREFIX=/usr/local/haproxy
  #mkdir -p /usr/local/haproxy/conf
  mkdir -p /etc/haproxy
  #touch /usr/local/haproxy/conf/haproxy.cfg
  ln -s /usr/local/haproxy/conf/haproxy.cfg /etc/haproxy/haproxy.cfg
  #mkdir -p /usr/local/haproxy/log
  #touch /usr/local/haproxy/log/haproxy.log
  ln -s /usr/local/haproxy/log/haproxy.log /var/log/haproxy.log
  #cp /opt/haproxy-1.7.1/examples/haproxy.init /etc/rc.d/init.d/haproxy
  cp /usr/local/haproxy/rc.d/init.d/haproxy.init /etc/rc.d/init.d/haproxy
  chmod 755 /etc/rc.d/init.d/haproxy
  chkconfig haproxy on
  ln -s /usr/local/haproxy/sbin/haproxy /usr/sbin
  log_info "-----install haproxy end-----"
}

