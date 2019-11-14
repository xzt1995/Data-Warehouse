

# 电商平台数据仓库搭建

## 项目需求

### 1 数据采集平台搭建

### 2 实现用户行为数据仓库的分层搭建

### 3 实现业务数据仓库的分层搭建

### 4 针对数据仓库中的数据进行业务分析

该项目仅供个人学习使用

## 一 ： 前期准备

1 电脑推荐参数  处理器：i7   内存：16G  

2 开发工具：idea , VAware , Xshell , FileZilla , sublime。

3 虚拟机配置：linux 版本：centOS-6.8  , 配置3台服务器 ，开通SSH权限。

### 一：项目流程设计

![系统流程设计](https://github.com/xzt1995/Data-Warehouse/blob/master/img/%E7%B3%BB%E7%BB%9F%E6%B5%81%E7%A8%8B%E8%AE%BE%E8%AE%A1.png)

### 二：技术选型

数据采集传输：**Flume , Kafka , Sqoop** , Logstash ,DataX

数据存储：**Mysql , HDFS , HBase** , Redis , MongoDB

数据计算:  **Hive , Tez** , Flink , Storm

数据查询：**Presto , Druid** , Impala , Kylin



### 三：集群规划

![集群规划](C:\Users\onlyi\Desktop\集群规划.png)



### 四：linux 设置

为了后续开发准备，请在虚拟机上配置以下参数，强烈建议和我保持一致，避免后续开发出现问题；

#### 1 修改主机名，分别为 hadoop102 , hadoop103 , hadoop104

```linux
vi /etc/sysconfig/network
```

文件中内容

NETWORKING=yes

NETWORKING_IPV6=no

HOSTNAME=hadoop102

**注意：主机名称不要有“_”下划线**

```
[root@hadoop102 桌面]# vim /etc/hosts
```

添加内容（**前面的IP根据你们自己的虚拟机IP来配置！！！**）

```
192.168.1.102 hadoop102
192.168.1.103 hadoop103
192.168.1.104 hadoop104
```



#### 2 关闭防火墙

```
[root@hadoop102桌面]#chkconfig iptables off
```

#### 3 创建新用户并配置root权限

添加xzt用户，并对其设置密码。

```
[root@hadoop102~]#useradd xzt
```

```
[root@hadoop102~]#passwd xzt
```

修改配置文件

```
[root@hadoop102~]#vi /etc/sudoers
```

修改 /etc/sudoers 文件，找到下面一行(91行)，在root下面添加一行，如下所示：

\##Allow root to run any commands anywhere

root    ALL=(ALL)     ALL

xzt   ALL=(ALL)    ALL

或者配置成采用sudo命令时，不需要输入密码

\##Allow root to run any commands anywhere

root      ALL=(ALL)     ALL

xzt   ALL=(ALL)    NOPASSWD:ALL

#### 4 用普通用户在/opt目录下创建一个文件夹

```
[xzt@hadoop102 opt]$ sudo mkdir module
[xzt@hadoop102 opt]$ sudo mkdir software
```

修改文件夹所有者

```
[xzt@hadoop102 opt]$ sudo chown xzt:xzt module/ software/
```

#### 5 安装JDK8

步骤省略





注意：以上几步在三台服务器都要操作一遍！！



## 二：数据生成

由于是个人学习，我们的数据是利用java工程自动生成，数据格式参考当前企业中广泛采用的数据类型。

### 1 埋点数据基本格式

（1）  公共字段：基本所有安卓手机都包含的字段

（2 ） 业务字段：埋点上报的字段，有具体的业务类型

下面就是一个示例，表示业务字段的上传。

```
{
"ap":"xxxxx",//项目数据来源 app pc
"cm": {  //公共字段
		"mid": "",  // (String) 设备唯一标识
        "uid": "",  // (String) 用户标识
        "vc": "1",  // (String) versionCode，程序版本号
        "vn": "1.0",  // (String) versionName，程序版本名
        "l": "zh",  // (String) 系统语言
        "sr": "",  // (String) 渠道号，应用从哪个渠道来的。
        "os": "7.1.1",  // (String) Android系统版本
        "ar": "CN",  // (String) 区域
        "md": "BBB100-1",  // (String) 手机型号
        "ba": "blackberry",  // (String) 手机品牌
        "sv": "V2.2.1",  // (String) sdkVersion
        "g": "",  // (String) gmail
        "hw": "1620x1080",  // (String) heightXwidth，屏幕宽高
        "t": "1506047606608",  // (String) 客户端日志产生时的时间
        "nw": "WIFI",  // (String) 网络模式
        "ln": 0,  // (double) lng经度
        "la": 0  // (double) lat 纬度
    },
"et":  [  //事件
            {
                "ett": "1506047605364",  //客户端事件产生时间
                "en": "display",  //事件名称
                "kv": {  //事件结果，以key-value形式自行定义
                    "goodsid": "236",
                    "action": "1",
                    "extend1": "1",
"place": "2",
"category": "75"
                }
            }
        ]
}

```

示例日志（服务器时间戳 | 日志）：

```
1540934156385|{
    "ap": "gmall", 
    "cm": {
        "uid": "1234", 
        "vc": "2", 
        "vn": "1.0", 
        "la": "EN", 
        "sr": "", 
        "os": "7.1.1", 
        "ar": "CN", 
        "md": "BBB100-1", 
        "ba": "blackberry", 
        "sv": "V2.2.1", 
        "g": "abc@gmail.com", 
        "hw": "1620x1080", 
        "t": "1506047606608", 
        "nw": "WIFI", 
        "ln": 0
    }, 
        "et": [
            {
                "ett": "1506047605364",  //客户端事件产生时间
                "en": "display",  //事件名称
                "kv": {  //事件结果，以key-value形式自行定义
                    "goodsid": "236",
                    "action": "1",
                    "extend1": "1",
"place": "2",
"category": "75"
                }
            },{
		        "ett": "1552352626835",
		        "en": "active_background",
		        "kv": {
			         "active_source": "1"
		        }
	        }
        ]
    }
}

```

### 2 事件日志数据

2.1 商品列表页(loading)

| 标签****           | 含义****                                   |
| ---------------- | ---------------------------------------- |
| action****       | 动作：开始加载=1，加载成功=2，加载失败=3                  |
| loading_time**** | **加载时长：计算下拉开始到接口返回数据的时间，（开始加载报****0****，加载成功或加载失败才上报时间）****** |
| loading_way****  | 加载类型：1-读取缓存，2-从接口拉新数据  （加载成功才上报加载类型）     |
| extend1****      | **扩展字段**** Extend1**                     |
| extend2****      | 扩展字段 Extend2                             |
| type****         | **加载类型：自动加载****=1****，用户下拽加载****=2****，底部加载****=3****（底部条触发点击底部提示条****/****点击返回顶部加载）****** |
| type1****        | 加载失败码：把加载失败状态码报回来（报空为加载成功，没有失败）          |

2.2 商品点击(display)

| 标签****       | 含义****                     |
| ------------ | -------------------------- |
| action****   | 动作：曝光商品=1，点击商品=2，          |
| goodsid****  | 商品ID（服务端下发的ID）             |
| place****    | 顺序（第几条商品，第一条为0，第二条为1，如此类推） |
| extend1****  | 曝光类型：1 - 首次曝光 2-重复曝光       |
| category**** | 分类ID（服务端定义的分类ID）           |

2.3 商品详情页(newsdetail)

| 标签****            | 含义****                                   |
| ----------------- | ---------------------------------------- |
| entry****         | 页面入口来源：应用首页=1、push=2、详情页相关推荐=3           |
| action****        | 动作：开始加载=1，加载成功=2（pv），加载失败=3, 退出页面=4      |
| goodsid****       | 商品ID（服务端下发的ID）                           |
| show_style****    | 商品样式：0、无图、1、一张大图、2、两张图、3、三张小图、4、一张小图、5、一张大图两张小图 |
| news_staytime**** | 页面停留时长：从商品开始加载时开始计算，到用户关闭页面所用的时间。若中途用跳转到其它页面了，则暂停计时，待回到详情页时恢复计时。或中途划出的时间超过10分钟，则本次计时作废，不上报本次数据。如未加载成功退出，则报空。 |
| loading_time****  | 加载时长：计算页面开始加载到接口返回数据的时间 （开始加载报0，加载成功或加载失败才上报时间） |
| type1****         | 加载失败码：把加载失败状态码报回来（报空为加载成功，没有失败）          |
| category****      | 分类ID（服务端定义的分类ID）                         |

2.4 广告(ad)

| 标签****         | 含义****                                   |
| -------------- | ---------------------------------------- |
| entry****      | 入口：商品列表页=1  应用首页=2 商品详情页=3               |
| action****     | 动作：请求广告=1 取缓存广告=2  广告位展示=3 广告展示=4 广告点击=5 |
| content****    | 状态：成功=1  失败=2                            |
| detail****     | 失败码（没有则上报空）                              |
| source****     | 广告来源:admob=1 facebook=2  ADX（百度）=3 VK（俄罗斯）=4 |
| behavior****   | 用户行为：  主动获取广告=1    被动获取广告=2              |
| newstype****   | Type: 1-  图文 2-图集 3-段子 4-GIF 5-视频 6-调查 7-纯文 8-视频+图文  9-GIF+图文  0-其他 |
| show_style**** | 内容样式：无图(纯文字)=6 一张大图=1  三站小图+文=4 一张小图=2 一张大图两张小图+文=3 图集+文 = 5   一张大图+文=11   GIF大图+文=12  视频(大图)+文 = 13  来源于详情页相关推荐的商品，上报样式都为0（因为都是左文右图） |

2.5 消息通知(notification)

| 标签****      | 含义****                                   |
| ----------- | ---------------------------------------- |
| action****  | 动作：通知产生=1，通知弹出=2，通知点击=3，常驻通知展示（不重复上报，一天之内只报一次）=4 |
| type****    | 通知id：预警通知=1，天气预报（早=2，晚=3），常驻=4           |
| ap_time**** | 客户端弹出时间                                  |
| content**** | 备用字段                                     |

2.6 用户前台活跃(active_foreground)

| 标签****      | 含义****                  |
| ----------- | ----------------------- |
| push_id**** | 推送的消息的id，如果不是从推送消息打开，传空 |
| access****  | 1.push  2.icon 3.其他     |

2.7 用户后台活跃(active_background)

| 标签****            | 含义****                                   |
| ----------------- | ---------------------------------------- |
| active_source**** | 1=upgrade,2=download(下载),3=plugin_upgrade |

2.8 评论（comment）

| **序号** | **字段名称**     | **字段描述**                 | **字段类型** | **长度** | **允许空** | **缺省值** |
| ------ | ------------ | ------------------------ | -------- | ------ | ------- | ------- |
| 1      | comment_id   | 评论表                      | int      | 10,0   |         |         |
| 2      | userid       | 用户id                     | int      | 10,0   | √       | 0       |
| 3      | p_comment_id | 父级评论id(为0则是一级评论,不为0则是回复) | int      | 10,0   | √       |         |
| 4      | content      | 评论内容                     | string   | 1000   | √       |         |
| 5      | addtime      | 创建时间                     | string   |        | √       |         |
| 6      | other_id     | 评论的相关id                  | int      | 10,0   | √       |         |
| 7      | praise_count | 点赞数量                     | int      | 10,0   | √       | 0       |
| 8      | reply_count  | 回复数量                     | int      | 10,0   | √       | 0       |

2.9 收藏（favorites）

| **序号** | **字段名称**  | **字段描述** | **字段类型** | **长度** | **允许空** | **缺省值** |
| ------ | --------- | -------- | -------- | ------ | ------- | ------- |
| 1      | id        | 主键       | int      | 10,0   |         |         |
| 2      | course_id | 商品id     | int      | 10,0   | √       | 0       |
| 3      | userid    | 用户ID     | int      | 10,0   | √       | 0       |
| 4      | add_time  | 创建时间     | string   |        | √       |         |

2.10点赞（praise）

| **序号** | **字段名称**  | **字段描述**                         | **字段类型** | **长度** | **允许空** | **缺省值** |
| ------ | --------- | -------------------------------- | -------- | ------ | ------- | ------- |
| 1      | id        | 主键id                             | int      | 10,0   |         |         |
| 2      | userid    | 用户id                             | int      | 10,0   | √       |         |
| 3      | target_id | 点赞的对象id                          | int      | 10,0   | √       |         |
| 4      | type      | 点赞类型 1问答点赞 2问答评论点赞 3 文章点赞数4 评论点赞 | int      | 10,0   | √       |         |
| 5      | add_time  | 添加时间                             | string   |        | √       |         |

2.11错误日志

| errorBrief****  | 错误摘要 |
| --------------- | ---- |
| errorDetail**** | 错误详情 |

### 3 启动日志数据

| 标签****           | 含义****                                   |
| ---------------- | ---------------------------------------- |
| entry****        | 入口： push=1，widget=2，icon=3，notification=4, lockscreen_widget =5 |
| open_ad_type**** | 开屏广告类型:  开屏原生广告=1, 开屏插屏广告=2              |
| action****       | 状态：成功=1  失败=2                            |
| loading_time**** | 加载时长：计算下拉开始到接口返回数据的时间，（开始加载报0，加载成功或加载失败才上报时间） |
| detail****       | 失败码（没有则上报空）                              |
| extend1****      | 失败的message（没有则上报空）                       |
| en               | 日志类型start                                |

### 4 数据生成脚本

用idea打开\jars\java下的logcollector工程，打包（带依赖），后续装完Hadoop和zookeeper后使用。

## 三：安装Hadoop（以下步骤使用我们创建的用户xzt来操作，不要用root）

### 1 集群规划

|      | 服务器hadoop102       | 服务器hadoop103                 | 服务器hadoop104                |
| ---- | ------------------ | ---------------------------- | --------------------------- |
| HDFS | NameNode  DataNode | DataNode                     | DataNode  SecondaryNameNode |
| Yarn | NodeManager        | Resourcemanager  NodeManager | NodeManager                 |

### 2 分发脚本编写

1 在Hadoop102 的home 目录下创建bin 文件夹，并编写脚本，该脚本可以将102上的文件同时同步到103，104

```
[xzt@hadoop102 ~]$ mkdir bin
[xzt@hadoop102 ~]$ cd bin/
[xzt@hadoop102 bin]$ touch xsync
[xzt@hadoop102 bin]$ vi xsync
```

```shell
#!/bin/bash
#1 获取输入参数个数，如果没有参数，直接退出
pcount=$#
if((pcount==0)); then
echo no args;
exit;
fi

#2 获取文件名称
p1=$1
fname=`basename $p1`
echo fname=$fname

#3 获取上级目录到绝对路径
pdir=`cd -P $(dirname $p1); pwd`
echo pdir=$pdir

#4 获取当前用户名称
user=`whoami`

#5 循环
for((host=103; host<105; host++)); do
        echo ------------------- hadoop$host --------------
        rsync -rvl $pdir/$fname $user@hadoop$host:$pdir
done

```

2 修改脚本权限

```
[xzt@hadoop102 bin]$ chmod 777 xsync
```

注意：如果将xsync放到/home/atguigu/bin目录下仍然不能实现全局使用，可以将xsync移动到/usr/local/bin目录下。

### 3 安装Hadoop

1 用filezilla工具将hadoop-2.7.2.tar.gz导入到opt目录下面的software文件夹下面.

2 进入到Hadoop安装包路径下

```
[xzt@hadoop102 ~]$ cd /opt/software/
```

3 解压安装文件到/opt/module下面

```
[xztu@hadoop101\2 software]$ tar -zxvf hadoop-2.7.2.tar.gz -C /opt/module/
```

4 查看是否解压成功

```
[xzt@hadoop102 software]$ ls /opt/module/
hadoop-2.7.2
```

5 将Hadoop添加到环境变量

（1）获取Hadoop安装路径

```
[xzt@hadoop102hadoop-2.7.2]$ pwd
```

```
/opt/module/hadoop-2.7.2
```

（2）打开/etc/profile文件

```
[xzt@hadoop102hadoop-2.7.2]$ sudo vi /etc/profile
```

在profile文件末尾添加JDK路径：（shitf+g）

```
##HADOOP_HOME

exportHADOOP_HOME=/opt/module/hadoop-2.7.2

exportPATH=PATH:HADOOP_HOME/bin

exportPATH=PATH:HADOOP_HOME/sbin

```

（3）保存后退出

```
:wq
```

   (4）让修改后的文件生效

```
[xzt@hadoop102 hadoop-2.7.2]$ source /etc/profile
```

6.    测试是否安装成功

```
[xzt@hadoop102 hadoop-2.7.2]$ hadoop version
```

```
Hadoop2.7.2
```

7.    重启(如果Hadoop命令不能用再重启)

```
[xzt@hadoop102 hadoop-2.7.2]$ sync
```

```
[xzt@hadoop102 hadoop-2.7.2]$ sudo reboot
```

### 4 hadoop目录结构

```
[xzt@hadoop102 hadoop-2.7.2]$ ll
总用量 52
drwxr-xr-x. 2 xzt xzt  4096 5月  22 2017 bin
drwxr-xr-x. 3 xzt xzt  4096 5月  22 2017 etc
drwxr-xr-x. 2 xzt xzt  4096 5月  22 2017 include
drwxr-xr-x. 3 xzt xzt  4096 5月  22 2017 lib
drwxr-xr-x. 2 xzt xzt  4096 5月  22 2017 libexec
-rw-r--r--. 1 xzt xzt 15429 5月  22 2017 LICENSE.txt
-rw-r--r--. 1 xzt xzt   101 5月  22 2017 NOTICE.txt
-rw-r--r--. 1 xzt xzt  1366 5月  22 2017 README.txt
drwxr-xr-x. 2 xzt xzt  4096 5月  22 2017 sbin
drwxr-xr-x. 4 xzt xzt  4096 5月  22 2017 share

```

（1）bin目录：存放对Hadoop相关服务（HDFS,YARN）进行操作的脚本

（2）etc目录：Hadoop的配置文件目录，存放Hadoop的配置文件

（3）lib目录：存放Hadoop的本地库（对数据进行压缩解压缩功能）

（4）sbin目录：存放启动或停止Hadoop相关服务的脚本

（5）share目录：存放Hadoop的依赖jar包、文档、和官方案例



### 5 集群配置

#### 集群部署规划

|      | hadoop102          | hadoop103                    | hadoop104                   |
| ---- | ------------------ | ---------------------------- | --------------------------- |
| HDFS | NameNode  DataNode | DataNode                     | SecondaryNameNode  DataNode |
| YARN | NodeManager        | ResourceManager  NodeManager | NodeManager                 |

#### 配置集群

（1）核心配置文件

配置core-site.xml

```
[xzt@hadoop102 hadoop-2.7.2]$ vim etc/hadoop/core-site.xml
```

在该文件中编写如下配置

```
<!--指定HDFS中NameNode的地址 -->

<property>

     <name>fs.defaultFS</name>

      <value>hdfs://hadoop102:9000</value>

</property>

 

<!--指定Hadoop运行时产生文件的存储目录 -->

<property>

     <name>hadoop.tmp.dir</name>

     <value>/opt/module/hadoop-2.7.2/data/tmp</value>

</property>

```

（2）HDFS配置文件

配置hadoop-env.sh

```
[xzt@hadoop102 hadoop-2.7.2]$ vim etc/hadoop/hadoop-env.sh 
export JAVA_HOME=/opt/module/jdk1.8.0_144(根据你自己安装JDK的路径来选择)
```

配置hdfs-site.xml

```
[xzt@hadoop102 hadoop-2.7.2]$ vim etc/hadoop/hdfs-site.xml 
```

在该文件中编写如下配置

```
<property>

     <name>dfs.replication</name>

     <value>1</value>

</property>

 

<!-- 指定Hadoop辅助名称节点主机配置 -->

<property>

     <name>dfs.namenode.secondary.http-address</name>

     <value>hadoop104:50090</value>

</property>

```



（3）YARN配置文件

配置yarn-env.sh

```
[xzt@hadoop102 hadoop-2.7.2]$ vim etc/hadoop/yarn-env.sh 
export JAVA_HOME=/opt/module/jdk1.8.0_144(根据你自己安装JDK的路径来选择)
```

配置yarn-site.xml

```
[xzt@hadoop102 hadoop-2.7.2]$ vim etc/hadoop/yarn-site.xml 
```

在该文件中增加如下配置

```
<!--Reducer获取数据的方式 -->

<property>

     <name>yarn.nodemanager.aux-services</name>

     <value>mapreduce_shuffle</value>

</property>

 

<!--指定YARN的ResourceManager的地址 -->

<property>

     <name>yarn.resourcemanager.hostname</name>

     <value>hadoop103</value>

</property>

```

（4）MapReduce配置文件

配置mapred-env.sh

```
[xzt@hadoop102 hadoop-2.7.2]$ vim etc/hadoop/mapred-env.sh 
export JAVA_HOME=/opt/module/jdk1.8.0_144(根据你自己安装JDK的路径来选择)
```



配置mapred-site.xml

```
[xzt@hadoop102 hadoop-2.7.2]$ cp etc/hadoop/mapred-site.xml.template etc/hadoop/mapred-site.xml
[xzt@hadoop102 hadoop-2.7.2]$ vi etc/hadoop/mapred-site.xml
```



在该文件中增加如下配置

```
<!--指定MR运行在Yarn上 -->

<property>

     <name>mapreduce.framework.name</name>

     <value>yarn</value>

</property

<!-- 历史服务器端地址 -->
<property>
<name>mapreduce.jobhistory.address</name>
<value>hadoop101:10020</value>
</property>

<!-- 历史服务器web端地址 -->
<property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>hadoop101:19888</value>
</property>



```

（5） 在集群上分发配置好的Hadoop配置文件

```
[xzt@hadoop102 module]$ xsync hadoop-2.7.2/
```

### 6 群起集群

#### 1 配置slaves

```
[xzt@hadoop102 hadoop-2.7.2]$ vi etc/hadoop/slaves 
```

添加以下内容

```
hadoop102
hadoop103
hadoop104
```

分发slaves

```
[xzt@hadoop102 hadoop-2.7.2]$ xsync etc/hadoop/slaves 
```

**注意：该文件中添加的内容结尾不允许有空格，文件中不允许有空行。**

#### 2 集群启动

（1）**如果集群是第一次启动，需要格式化NameNode**（注意格式化之前，一定要先停止上次启动的所有namenode和datanode进程，然后再删除data和log数据）

```
[xzt@hadoop102 hadoop-2.7.2]$ bin/hdfs namenode -format
```

（2）启动HDFS

```
[xzt@hadoop102 hadoop-2.7.2]$ sbin/start-dfs.sh 
```

（3) 启动YARN

```
[xzt@hadoop103 hadoop-2.7.2]$ sbin/start-yarn.sh 
```

**注意：NameNode和ResourceManger如果不是同一台机器，不能在NameNode上启动 YARN，应该在ResouceManager所在的机器上启动YARN，所以我们要切换到Hadoop103来启动yarn。**

（4）查看集群启动是否成功

在三台服务器分别使用jps命令来查看服务是否启动成功

```
[xzt@hadoop102 hadoop-2.7.2]$ jps
4903 Jps
4360 DataNode
4172 NameNode
4718 NodeManager

[xzt@hadoop103 hadoop-2.7.2]$ jps
4168 NodeManager
4650 Jps
3855 DataNode
3999 ResourceManager

[xzt@hadoop104 ~]$ jps
3904 SecondaryNameNode
4210 Jps
3784 DataNode
4029 NodeManager

成功情况下，三台服务器各有四个进程，如果失败的话请检查一下配置文件是否写错，改完后再格式化一下namenode再次启动

```

（5）web查看集群

​    浏览器中输入：<http://hadoop102:50070/explorer.html#/>



 浏览器中输入: <http://hadoop103:8088/cluster>





看到这两个页面就表示集群安装成功了。



（6） 集群启动和关闭命令（**关闭虚拟机前一定要关闭集群！！！否则有可能会导致集群错误**）

整体启动/停止HDFS

start-dfs.sh   /  stop-dfs.sh

 整体启动/停止YARN

 start-yarn.sh  /  stop-yarn.sh



### 7配置lzo压缩

1）先下载lzo的jar项目(我在jar/hadoop里面已经放了一个jar包，嫌麻烦的直接用)

<https://github.com/twitter/hadoop-lzo/archive/master.zip>

2）下载后的文件名是hadoop-lzo-master，它是一个zip格式的压缩包，先进行解压，然后用maven编译。生成hadoop-lzo-0.4.20.jar。

3）将编译好后的hadoop-lzo-0.4.20.jar 放入hadoop-2.7.2/share/hadoop/common/

4）同步hadoop-lzo-0.4.20.jar到hadoop103、hadoop104

```
[xzt@hadoop102common]$ xsync hadoop-lzo-0.4.20.jar
```

5）core-site.xml增加配置支持LZO压缩

```

<configuration>

<property>
<name>io.compression.codecs</name>
<value>
org.apache.hadoop.io.compress.GzipCodec,
org.apache.hadoop.io.compress.DefaultCodec,
org.apache.hadoop.io.compress.BZip2Codec,
org.apache.hadoop.io.compress.SnappyCodec,
com.hadoop.compression.lzo.LzoCodec,
com.hadoop.compression.lzo.LzopCodec
</value>
</property>

<property>
    <name>io.compression.codec.lzo.class</name>
    <value>com.hadoop.compression.lzo.LzoCodec</value>
</property>


</configuration>

```

5）同步core-site.xml到hadoop103、hadoop104

```
[xzt@hadoop102 hadoop]$ xsynccore-site.xml
```

