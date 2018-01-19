# ansible study

## 一、安装

#### 1、安装条件：

  centos7.3
  python 2.6~2.7
  linux下默认使用 sftp（如果 sftp 不可用，可在 ansible.cfg 中配置成 scp 的方式.），windows为 winrm

#### 2、安装：

- 可直接 yum安装
    sudo yum install ansible -y
- rpm 安装
    sudo yum install git python2-pip asciidoc python-jinja2 python-paramiko python2-cryptography sshpass
    sudo pip install --upgrade pip && sudo pip install Jinja2
    git clone git://github.com/ansible/ansible.git
    cd ./ansible
    make rpm
    sudo rpm -Uvh ~/rpm-build/ansible-*.noarch.rpm

#### 3、windows支持

> 以Win-server 2012 为例

 ```
    1、查询powershell 版本： get-host
    注意：如果在 3.0以下 需要升级到 3.0 以上
    http://www.cnblogs.com/kingleft/p/6391652.html
    2、
    将winrm的配置文件设置成下面配置，
    > winrm set winrm/config/service ‘@{AllowUnencrypted="true"}‘
    > winrm set winrm/config/service/auth ‘@{Basic="true"}‘

    3、配置 ansible host 进行测试：
    # ansible all --limit=192.168.71.44 -m win_ping

    4、(最佳实践) 升级 powershell 到5.0 ，需要同步升级framework到 4.6
    Powershell 5 下载地址 https://www.microsoft.com/en-us/download/confirmation.aspx?id=50395
 ```

## 二、配置

#### 1、hosts 中的参数
    ansible_ssh_host   
    #用于指定被管理的主机的真实IP
    ansible_ssh_port     
    #用于指定连接到被管理主机的ssh端口号，默认是22 
    ansible_ssh_user     
    #ssh连接时默认使用的用户名 
    ansible_ssh_pass     
    #ssh连接时的密码 
    ansible_sudo_pass     
    #使用sudo连接用户时的密码 
    ansible_sudo_exec     
    #如果sudo命令不在默认路径，需要指定sudo命令路径 
    ansible_ssh_private_key_file     
    #秘钥文件路径，秘钥文件如果不想使用ssh-agent管理时可以使用此选项 ansible_shell_type     
    #目标系统的shell的类型，默认sh 
    ansible_connection     
    #SSH 连接的类型： local , ssh , paramiko，在 ansible 1.2 之前默认是 paramiko ，后来智能选择，优先使用基于 ControlPersist 的 ssh （支持的前提） windows为 winrm

    ansible_python_interpreter     
    #用来指定python解释器的路径，默认为/usr/bin/python 同样可以指定ruby 、perl 的路径 
    ansible_*_interpreter    
    #其他解释器路径，用法和ansible_python_interpreter类似，这里"*"可以是ruby或才perl等其他语言

#### 2、ansible.cfg 配置
     + 读取顺序：
       - ANSIBLE_CONFIG (一个环境变量)
       - ansible.cfg (位于当前目录中)
       - .ansible.cfg (位于家目录中)
       - /etc/ansible/ansible.cfg

    + 重要配置说明：
      action_plugins ：配置一些底层模块加载路径
        action_plugins = ~/.ansible/plugins/action_plugins/:/usr/share/ansible_plugins/action_plugins

      error_on_undefined_vars：如果所引用的变量名称错误的话, 将会导致ansible在执行步骤上失败

      forks：这个选项设置在与主机通信时的默认并行进程数（默认为5）

      gathering：这个设置控制默认facts收集（远程系统变量）. 默认值为’implicit’, 每一次play,facts都会被手机,除非设置’gather_facts: False’. 选项‘explicit’正好相反,facts不会被收集,直到play中需要. ‘smart’选项意思是,没有facts的新hosts将不会被扫描, 但是如果同样一个主机,在不同的plays里面被记录地址,在playbook运行中将不会通信.这个选项当有需求节省fact收集时比较有用.

      host_key_checking：检测主机密钥（默认为 true）

      inventory：默认库文件位置
        inventory = /etc/ansible/hosts

      module_name：这个是/usr/bin/ansible的默认模块名（-m）. 默认是’command’模块

      poll_interval：ansible的异步任务中 设置轮询频率

      private_key_file：设置密钥文件默认位置，避免每次使用`–ansible-private-keyfile`

      remote_tmp:设置远程临时文件的默认路径；Ansible 通过远程传输模块到远程主机,然后远程执行,执行后在清理现场.

      roles_path：设置role的路径，多个地址可用冒号隔开

      timeout：默认ssh尝试连接的超时时间

      transport：如果”-c <transport_name>” 选项没有在使用/usr/bin/ansible 或者 /usr/bin/ansible-playbook 特指的话,这个参数提供了默认通信机制.默认 值为’smart’, 如果本地系统支持 ControlPersist技术的话,将会使用(基于OpenSSH)‘ssh’,如果不支持讲使用‘paramiko’.其他传输选项包括‘local’, ‘chroot’,’jail’等等.

      scp_if_ssh :.如果这个设置为True,scp将代替sftp用来为远程主机传输文件

## 三、Ad-Hoc

## 四、playbook

#### 1、变量
  变量名可以为字母,数字以及下划线.变量始终应该以字母开头；为了避免大小写问题,不建议使用 “驼峰式”。
    * 使用 --extra-vars（或 -e ） 选项指定变量
      eg: ansible-playbook  env.yml -e "environment_file=/etc/profile environment_config={'TEST_1':'/data'} "
    * 通过vars模块
      ---
      - hosts: all
        vars:
          foo: bar
    * 定义独立的vars.yaml 文件，由 vars_files 模块引入
      ---
      - hosts: all
        vars_files:
          - vars.yaml
    * 优先级（由高到低）：
      extra vars (在命令行中使用 -e)优先级最高
      然后是在inventory中定义的连接变量(比如ansible_ssh_user)
      接着是大多数的其它变量(命令行转换,play中的变量,included的变量,role中的变量等)
      然后是在inventory定义的其它变量
      然后是由系统发现的facts
      然后是 "role默认变量", 这个是最默认的值,很容易丧失优先权

#### 2、facts:
    获取指定机器系统信息 可以通过setup模块获取
    如果不需要收集，可以通过配置 gather_facts: no 进行关闭

#### 3、常用模块说明
######  1) copy/synchronize/unarchive :
           copy: 适合单个或少量文件
           synchronize:复制整个目录
           unarchive:复制一个归档

######  2) pre_tasks/post_tasks ：主任务之前和之后运行的任务

######  3) lineinfile ： 文件中搜索，替换 移除文件的单行  # 多行替换 移除参考replace模块
    ```
    Options: (= is mandatory)(= 后面的参数是强制要有的)
    - backrefs(default=no)
    　　与state=present一起使用  
    　　* 支持反向引用
    　　* 稍微改变了模块的操作方式
    　　  - 前插'insertbefore'，后插'insertafter'失效
    　　  - 如果匹配到 替换最后一个匹配结果
    　　  - 如果未匹配到 不做任何改变
    - dest 被编辑的文件
    - insertafter 需要声明 state=present 在匹配行后插入，如果未匹配到则默认为EOF
    - insertbefore 需要声明 state=present  在匹配行前插入，如果未匹配到则默认为BOF
    - line 需要声明 state=present　插入或替换的字符串
    - regexp 使用正则匹配
    - state(default=present)
    　　present 如果匹配到就替换(最后一个匹配结果) #如果未设置backrefs=yes 未匹配到也会在最后插入line
    　　absent 移除匹配行(所有匹配到的)
    ```

#### 4、加密模块 vault
(略)

#### 5、流程控制 (if/then/when)
sss

## 五、role

## 六、ansible-api

## 七、实战

    facts
    应用部署：
    ansible-playbook -i /etc/ansible/hosts –limit=192.168.110.98 download.yml -e “source_url=’https://dl.yihecloud.com/install/etcd/etcd.tar.gz‘ base_path=’/data’ script_url=’https://dl.yihecloud.com/install/k8s.sh‘ script_file=’install.sh’” -vvv
    ansible-playbook -i /etc/ansible/hosts –limit=192.168.110.98 mount_disk.yaml -e ‘{“disk_package_use”:”yum”,”disk_additional_disks”:[{“disk”:”/dev/vdb”,”fstype”:”ext4”,”mount_options”:”defaults”,”mount”:”/data”,”user”:”root”,”group”:”root”,”disable_periodic_fsck”:”false”}]}’ -vvv
