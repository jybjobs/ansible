haproxy
=========
haproxy 单机部署，Frontend、backend、acl、member动态配置

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------


deploy_ops: install 操作类型(默认安装): install(安装)、config_frontend\config_backend\config_member 
## install
```
var_manageKey:  ssh访问密钥(公钥)
var_soft_download: 安装包下载地址
var_mode: single 集群类型
var_keep_version: keepalived 安装版本
var_ps: 1 控制分支选择变量((ps:主备，主为1，备为2))
#var_vip
var_localip  IP地址
var_maxconn 最大连接数
var_keep_alive http keepalive 超时时间(默认: 10s)

```
## config
```
config_ops: 配置类型：add\delete\update
var_frontend_name: frontend 名称
var_port 端口(默认: 80)
var_protocol 协议(默认 http)
var_balance 均衡策略(默认 roundrobin)
var_backend_name： backend 名称
var_acls：acl list (eg: [{"name":"acl01","operator":"path_beg","value":"/ops"}])
var_servers: member信息(eg: [{"balances":"weight 1","host":"192.168.110.7:8088","id":"member1107"},{"balances":"inter 20 fall 3 weight 30","host":"192.168.110.8:8088","id":"member1108"}])
var
```

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: haproxy, x: v1.0 }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).

Demo
------------------
http添加代理：
  ansible-playbook -i /etc/ansible/inventory  --limit=192.168.71.117 /etc/ansible/scripts/setup-2_0.yaml -e '{"roless":"haproxy", "config_ops":"add", "var_global_id":"prj_1520823398543_20180320152306", "var_servers":[{"balances":"weight 1","host":"172.0.0.1:8080","id":"prj_1520823398543_20180320152306_u0OHSJBr"}],"var_acls":[{"name":"prj-1520823398543-20180320152306_KBiXNN9j","operator":"path_beg","value":"/ops"},{"name":"prj-1520823398543-20180320152306_Vj6xnCDq","operator":"hdr_beg(host)","value":"www.test.com"}], "var_frontend_name":"main", "var_bpath":"/aa", "var_backend_name":"roundrobin", "var_protocol":"http", "deploy_ops":"config_backend"}'
