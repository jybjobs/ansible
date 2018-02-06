# ansible developing plugins

> 插件是增强Ansible核心功能的代码片断。Ansible提供了一些方便的插件，也可以较容易地写你自己的插件。

以下类型的插件可用：

    动作插件 是模块的前端，可以在调用模块之前在控制器上执行动作。
    缓存插件 用于保存“事实”缓存，以避免成本高昂的事实收集操作。
    回调插件 提供了ansible事件的钩子，可以用来处理结果显示或log记录。
    连接插件 定义了如何与inventory 主机进行通信。
    过滤插件 允许你操作Ansible和(或)模板中的数据。这是一个Jinja2功能; Ansible发送额外的过滤器插件。
    查找插件 用于从外部来源提取数据。这些是使用定制的Jinja2函数实现的。
    策略插件 控制play和执行逻辑的流程。
    Shell插件 处理Ansible在远程主机上可能遇到的shell的低级命令和格式。
    测试插件 允许您验证Ansible play 和(或) 模板中的数据。这是一个Jinja2功能; Ansible提供额外的测试插件。
    Vars插件 将额外的变量数据注入到Ansible运行中，这些运行并不是来自inventory，playbook 或命令行。

这里我重点分享一下 callback plugin 的开发和使用。

##  自定义callback_plugins

#### 1. 开发回调插件

> 回调插件是通过创建一个Base（Callbacks）类作为父类的新类来创建的：

```
    from ansible.plugins.callback import CallbackBase
    from ansible import constants as C

    class CallbackModule(CallbackBase):
        pass
```
覆盖你想提供回调的CallbackBase的具体方法。用于Ansible版本2.0和更高版本的插件，只覆盖以v2开头的方法即可。对于您可以重写方法的完整列表，请参阅__init__.py在../ansible/plugins/callback/。

#### 2. 获得模板模块

> 官方提供了一些示例模板，也可以参考这些[模板](https://github.com/ansible/ansible/blob/devel/lib/ansible/plugins/callback/)进行开发;

```
 log_plays 回调是如何拦截playbook事件日志文件的示例
 mail 回调是playbook完成时发送电子邮件。
 osx_say 回调 将在OS X上与playbook事件相关的计算机合成语音响应
```

#### 3. copy to callback_plugins
> cp self_logg_plays.py /usr/lib/python2.7/site-packages/ansible/plugins/callback/

#### 4. 修改配置文件
```
 # 添加自定义模块
 stdout_callback = actionable
 # 启用
 callback_whitelist = timer, mail, json, log_plays ,actionable
```

#### 5. 测试
> 执行一个playbook 示例，看log记录情况。

