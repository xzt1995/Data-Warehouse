

# 电商平台数据仓库搭建

## 项目需求

### 1 数据采集平台搭建

### 2 实现用户行为数据仓库的分层搭建

### 3 实现业务数据仓库的分层搭建

### 4 针对数据仓库中的数据进行业务分析

### 5 **该项目仅供个人学习使用**

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

![集群规划](https://github.com/xzt1995/Data-Warehouse/blob/master/img/%E9%9B%86%E7%BE%A4%E8%A7%84%E5%88%92.png)



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





**注意：以上几步在三台服务器都要操作一遍！！**



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

| 标签           | 含义                                       |
| ------------ | ---------------------------------------- |
| action       | 动作：开始加载=1，加载成功=2，加载失败=3                  |
| loading_time | 加载时长：计算下拉开始到接口返回数据的时间，（开始加载报0，加载成功或加载失败才上报时间） |
| loading_way  | 加载类型：1-读取缓存，2-从接口拉新数据  （加载成功才上报加载类型）     |
| extend1      | 扩展字段  Extend1                            |
| extend2      | 扩展字段  Extend2                            |
| type         | 加载类型：自动加载=1，用户下拽加载=2，底部加载=3（底部条触发点击底部提示条/点击返回顶部加载） |
| type1        | 加载失败码：把加载失败状态码报回来（报空为加载成功，没有失败）          |

2.2 商品点击(display)

| 标签       | 含义                         |
| -------- | -------------------------- |
| action   | 动作：曝光商品=1，点击商品=2，          |
| goodsid  | 商品ID（服务端下发的ID）             |
| place    | 顺序（第几条商品，第一条为0，第二条为1，如此类推） |
| extend1  | 曝光类型：1 - 首次曝光 2-重复曝光       |
| category | 分类ID（服务端定义的分类ID）           |

2.3 商品详情页(newsdetail)

| 标签            | 含义                                       |
| ------------- | ---------------------------------------- |
| entry         | 页面入口来源：应用首页=1、push=2、详情页相关推荐=3           |
| action        | 动作：开始加载=1，加载成功=2（pv），加载失败=3, 退出页面=4      |
| goodsid       | 商品ID（服务端下发的ID）                           |
| show_style    | 商品样式：0、无图、1、一张大图、2、两张图、3、三张小图、4、一张小图、5、一张大图两张小图 |
| news_staytime | 页面停留时长：从商品开始加载时开始计算，到用户关闭页面所用的时间。若中途用跳转到其它页面了，则暂停计时，待回到详情页时恢复计时。或中途划出的时间超过10分钟，则本次计时作废，不上报本次数据。如未加载成功退出，则报空。 |
| loading_time  | 加载时长：计算页面开始加载到接口返回数据的时间 （开始加载报0，加载成功或加载失败才上报时间） |
| type1         | 加载失败码：把加载失败状态码报回来（报空为加载成功，没有失败）          |
| category      | 分类ID（服务端定义的分类ID）                         |

2.4 广告(ad)

| 标签         | 含义****                                   |
| ---------- | ---------------------------------------- |
| entry      | 入口：商品列表页=1  应用首页=2 商品详情页=3               |
| action     | 动作：请求广告=1 取缓存广告=2  广告位展示=3 广告展示=4 广告点击=5 |
| content    | 状态：成功=1  失败=2                            |
| detail     | 失败码（没有则上报空）                              |
| source     | 广告来源:admob=1 facebook=2  ADX（百度）=3 VK（俄罗斯）=4 |
| behavior   | 用户行为：  主动获取广告=1    被动获取广告=2              |
| newstype   | Type: 1-  图文 2-图集 3-段子 4-GIF 5-视频 6-调查 7-纯文 8-视频+图文  9-GIF+图文  0-其他 |
| show_style | 内容样式：无图(纯文字)=6 一张大图=1  三站小图+文=4 一张小图=2 一张大图两张小图+文=3 图集+文 = 5   一张大图+文=11   GIF大图+文=12  视频(大图)+文 = 13  来源于详情页相关推荐的商品，上报样式都为0（因为都是左文右图） |

2.5 消息通知(notification)

| 标签      | 含义                                       |
| ------- | ---------------------------------------- |
| action  | 动作：通知产生=1，通知弹出=2，通知点击=3，常驻通知展示（不重复上报，一天之内只报一次）=4 |
| type    | 通知id：预警通知=1，天气预报（早=2，晚=3），常驻=4           |
| ap_time | 客户端弹出时间                                  |
| content | 备用字段                                     |

2.6 用户前台活跃(active_foreground)

| 标签      | 含义                      |
| ------- | ----------------------- |
| push_id | 推送的消息的id，如果不是从推送消息打开，传空 |
| access  | 1.push  2.icon 3.其他     |

2.7 用户后台活跃(active_background)

| 标签            | 含义                                       |
| ------------- | ---------------------------------------- |
| active_source | 1=upgrade,2=download(下载),3=plugin_upgrade |

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

| errorBrief  | 错误摘要 |
| ----------- | ---- |
| errorDetail | 错误详情 |

### 3 启动日志数据

| 标签           | 含义                                       |
| ------------ | ---------------------------------------- |
| entry        | 入口： push=1，widget=2，icon=3，notification=4, lockscreen_widget =5 |
| open_ad_type | 开屏广告类型:  开屏原生广告=1, 开屏插屏广告=2              |
| action       | 状态：成功=1  失败=2                            |
| loading_time | 加载时长：计算下拉开始到接口返回数据的时间，（开始加载报0，加载成功或加载失败才上报时间） |
| detail       | 失败码（没有则上报空）                              |
| extend1      | 失败的message（没有则上报空）                       |
| en           | 日志类型start                                |

### 4 数据生成脚本

用idea打开\jars\java下的logcollector工程，打包（带依赖），后续装完Hadoop和zookeeper后使用。







## 三：安装Hadoop（以下步骤使用我们创建的用户来操作，不要用root）

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

注意：如果将xsync放到/home/xzt/bin目录下仍然不能实现全局使用，可以将xsync移动到/usr/local/bin目录下。

### 3 安装Hadoop

Hadoop下载地址：

<https://archive.apache.org/dist/hadoop/common/hadoop-2.7.2/>

1 去用filezilla工具将hadoop-2.7.2.tar.gz导入到opt目录下面的software文件夹下面.

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

![namenode](https://github.com/xzt1995/Data-Warehouse/blob/master/img/namenode.png)

 浏览器中输入: <http://hadoop103:8088/cluster>


![yarn](https://github.com/xzt1995/Data-Warehouse/blob/master/img/yarn.png)


看到这两个页面就表示集群安装成功了。



（6） 集群启动和关闭命令（**关闭虚拟机前一定要关闭集群！！！否则有可能会导致集群错误**）

整体启动/停止HDFS

start-dfs.sh   /  stop-dfs.sh

 整体启动/停止YARN

 start-yarn.sh  /  stop-yarn.sh



### 7 配置lzo压缩

1）先下载lzo的jar项目(我在jars/hadoop里面已经放了一个jar包，嫌麻烦的直接用)

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

### 8 参数调优（本项目不需要，供学习使用）

#### 1）HDFS参数调优hdfs-site.xml

（1）dfs.namenode.handler.count=20 * log2(Cluster Size)，比如集群规模为10台时，此参数设置为60

```
Thenumber of Namenode RPC server threads that listen to requests from clients. Ifdfs.namenode.servicerpc-address is not configured then Namenode RPC serverthreads listen to requests from all nodes.

NameNode有一个工作线程池，用来处理不同DataNode的并发心跳以及客户端并发的元数据操作。对于大集群或者有大量客户端的集群来说，通常需要增大参数dfs.namenode.handler.count的默认值10。设置该值的一般原则是将其设置为集群大小的自然对数乘以20，即20logN，N为集群大小。

```

（2）编辑日志存储路径dfs.namenode.edits.dir设置与镜像文件存储路径dfs.namenode.name.dir尽量分开，达到最低写入延迟

#### 2）YARN参数调优yarn-site.xml

（1）情景描述：总共7台机器，每天几亿条数据，数据源->Flume->Kafka->HDFS->Hive

面临问题：数据统计主要用HiveSQL，没有数据倾斜，小文件已经做了合并处理，开启的JVM重用，而且IO没有阻塞，内存用了不到50%。但是还是跑的非常慢，而且数据量洪峰过来时，整个集群都会宕掉。基于这种情况有没有优化方案。

（2）解决办法：

内存利用率不够。这个一般是Yarn的2个配置造成的，单个任务可以申请的最大内存大小，和Hadoop单个节点可用内存大小。调节这两个参数能提高系统内存的利用率。

（a）yarn.nodemanager.resource.memory-mb

表示该节点上YARN可使用的物理内存总量，默认是8192（MB），注意，如果你的节点内存资源不够8GB，则需要调减小这个值，而YARN不会智能的探测节点的物理内存总量。

（b）yarn.scheduler.maximum-allocation-mb

单个任务可申请的最多物理内存量，默认是8192（MB）。

#### 3）Hadoop宕机

（1）如果MR造成系统宕机。此时要控制Yarn同时运行的任务数，和每个任务申请的最大内存。调整参数：yarn.scheduler.maximum-allocation-mb（单个任务可申请的最多物理内存量，默认是8192MB）

（2）如果写入文件过量造成NameNode宕机。那么调高Kafka的存储大小，控制从Kafka到HDFS的写入速度。高峰期的时候用Kafka进行缓存，高峰期过去数据同步会自动跟上。



## 四 zookeeper安装

### 1 集群规划

|           | 服务器hadoop102 | 服务器hadoop103 | 服务器hadoop104 |
| --------- | ------------ | ------------ | ------------ |
| Zookeeper | Zookeeper    | Zookeeper    | Zookeeper    |

### 2 安装步骤

#### 1 将jars/zookeeper下的安装包拷贝的102下的/opt/software目录下

#### 2 解压到/opt/module

```
[xzt@hadoop102 software]$ tar -zxvf zookeeper-3.4.10.tar.gz -C /opt/module/
```

#### 3 同步到103，104

```
[xzt@hadoop102 module]$ xsync zookeeper-3.4.10/
```

#### 4 配置服务器编号

（1）在/opt/module/zookeeper-3.4.10/这个目录下创建zkData

```
[xzt@hadoop102 zookeeper-3.4.10]$ mkdir zkData
```

（2）在/opt/module/zookeeper-3.4.10/zkData目录下创建一个myid的文件

```
[xzt@hadoop102 zkData]$ touch myid
```

**添加myid文件，注意一定要在linux里面创建，在notepad++里面很可能乱码**

（3）编辑myid文件

在文件中添加与server对应的编号：

```
2
```

（4）其他机器上配置

```
分别在hadoop103、hadoop104上添加myid文件中内容为3、4
```

#### 5 配置zoo.cfg文件

（1）重命名/opt/module/zookeeper-3.4.10/conf这个目录下的zoo_sample.cfg为zoo.cfg

```
[xzt@hadoop102conf]$ mv zoo_sample.cfg zoo.cfg
```

（2）打开zoo.cfg文件

```
1 修改数据存储路径配置

dataDir=/opt/module/zookeeper-3.4.10/zkData

2 增加如下配置

#######################cluster##########################

server.2=hadoop102:2888:3888

server.3=hadoop103:2888:3888

server.4=hadoop104:2888:3888

```



（3）同步zoo.cfg配置文件

```
[xzt@hadoop102 conf]$ xsync zoo.cfg
```

（4）配置参数解读

server.A=B:C:D。

**A**是一个数字，表示这个是第几号服务器；

集群模式下配置一个文件myid，这个文件在dataDir目录下，这个文件里面有一个数据就是A的值，Zookeeper启动时读取此文件，拿到里面的数据与zoo.cfg里面的配置信息比较从而判断到底是哪个server。

**B**是这个服务器的ip地址；

**C**是这个服务器与集群中的Leader服务器交换信息的端口；

**D**是万一集群中的Leader服务器挂了，需要一个端口来重新进行选举，选出一个新的Leader，而这个端口就是用来执行选举时服务器相互通信的端口。

#### 6  ZK集群启动停止脚本

1）在hadoop102的/home/xzt/bin目录下创建脚本

```
[xzt@hadoop102 bin]$ vim zk.sh
```

​        在脚本中编写如下内容

```
#! /bin/bash

case $1 in

"start"){

   for i in hadoop102 hadoop103 hadoop104

   do

      ssh $i "/opt/module/zookeeper-3.4.10/bin/zkServer.sh start"

   done

};;

"stop"){

   for i in hadoop102 hadoop103 hadoop104

   do

      ssh $i "/opt/module/zookeeper-3.4.10/bin/zkServer.sh stop"

   done

};;

"status"){

   for i in hadoop102 hadoop103 hadoop104

   do

      ssh $i "/opt/module/zookeeper-3.4.10/bin/zkServer.sh status"

   done

};;

esac

```

2）增加脚本执行权限

```
[xzt@hadoop102 bin]$ chmod 777 zk.sh
```

3）Zookeeper集群启动脚本

```
[xzt@hadoop102 module]$ zk.sh start
```

4）Zookeeper集群停止脚本

```
[xzt@hadoop102 module]$ zk.sh stop
```

#### 7 Linux环境变量

1）修改/etc/profile文件：用来设置系统环境参数，比如$PATH. 这里面的环境变量是对系统内所有用户生效。使用bash命令，需要source  /etc/profile一下。

2）修改~/.bashrc文件：针对某一个特定的用户，环境变量的设置只对该用户自己有效。使用bash命令，只要以该用户身份运行命令行就会读取该文件。

3）把/etc/profile里面的环境变量追加到~/.bashrc目录

```
[xzt@hadoop102 ~]$ cat /etc/profile>> ~/.bashrc

[xzt@hadoop103 ~]$ cat /etc/profile>> ~/.bashrc

[xzt@hadoop104 ~]$ cat /etc/profile>> ~/.bashrc

```

## 五 日志生成



#### 1）代码参数说明



```
// 参数一：控制发送每条的延时时间，默认是0

Longdelay = args.length > 0 ? Long.parseLong(args[0]) : 0L;

// 参数二：循环遍历次数

intloop_len = args.length > 1 ? Integer.parseInt(args[1]) : 1000;

```



#### 2）上传jar包

将之前生成的jar包 log-collector-0.0.1-SNAPSHOT-jar-with-dependencies.jar拷贝到hadoop102服务器/opt/module上，并同步到hadoop103的/opt/module路径下

```
[xzt@hadoop102 module]$ xsync log-collector-1.0-SNAPSHOT-jar-with-dependencies.jar
```

我的电脑是16G内存，经测试只能在103，102上执行数据采集flume,否则性能不够，集群会瘫痪，因此我们就在102，103上上传jar包 ，把104上面的jar包删除。

#### 3）在hadoop102上执行jar程序

```
[xzt@hadoop102 module]$ java -classpath log-collector-1.0-SNAPSHOT-jar-with-dependencies.jar  com.xzt.appclient.AppMain  >/opt/module/test.log
```



#### 4）在/tmp/logs路径下查看生成的日志文件

```
[xzt@hadoop102 module]$ cd /tmp/logs/

[xzt@hadoop102 logs]$ ls

app-2019-02-10.log

```

#### 5) 日志采集脚本编写

​       1）在/home/xzt/bin目录下创建脚本lg.sh

```
[xzt@hadoop102 bin]$ vim lg.sh
```

​        2）在脚本中编写如下内容

```
#! /bin/bash

	for i in hadoop102 hadoop103 
	do
		ssh $i "java -classpath /opt/module/log-collector-1.0-SNAPSHOT-jar-with-dependencies.jar com.xzt.appclient.AppMain $1 $2 >/opt/module/test.log &"
	done
```



3）修改脚本执行权限

```
[xzt@hadoop102 bin]$ chmod 777 lg.sh
```

4）启动脚本

```
[xzt@hadoop102 module]$ lg.sh 
```

5）分别在hadoop102、hadoop103的/tmp/logs目录上查看生成的数据

```
[xzt@hadoop102 logs]$ ls
app-2019-02-10.log
```

```
[xzt@hadoop103 logs]$ ls
app-2019-02-10.log
```

#### 6) 集群时间同步修改脚本

​	1）在/home/xzt/bin目录下创建脚本dt.sh

```
[xzt@hadoop102 bin]$ vim dt.sh
```

​        2）在脚本中编写如下内容

```
#!/bin/bash

log_date=$1

for i in hadoop102 hadoop103 hadoop104
do
	ssh -t $i "sudo date -s $log_date"
done

```

说明（ssh -t）：https://www.cnblogs.com/kevingrace/p/6110842.html

3）修改脚本执行权限

```
[xzt@hadoop102 bin]$ chmod 777 dt.sh
```

4）启动脚本

```
[xzt@hadoop102 bin]$ dt.sh 2019-2-10
[xzt@hadoop102 bin]$ date 
```

#### 7）集群所有进程查看脚本

1）在/home/xzt/bin目录下创建脚本xcall.sh,该脚本可以在三台服务器上同时执行同一个命令

```
[xzt@hadoop102 bin]$ vim xcall.sh
```

​        2）在脚本中编写如下内容

```
#! /bin/bash

for i in hadoop102 hadoop103 hadoop104
do
        echo --------- $i ----------
        ssh $i "$*"
done

```

3）修改脚本执行权限

```
[xzt@hadoop102 bin]$ chmod 777 xcall.sh
```


4）启动脚本

```
[xzt@hadoop102 bin]$ xcall.sh jps
```







## 六 采集日志flume 



### 1 集群规划

![日志采集flume](https://github.com/xzt1995/Data-Warehouse/blob/master/img/%E6%97%A5%E5%BF%97%E9%87%87%E9%9B%86flume.png)



从红框中选中的区域我们可以看到，服务器生成日志文件logFile，我们利用flume采集日志文件，然后将文件发给Kafka集群，此时的flume相当于Kafka的生产者。



### 2 flume安装

|             | 服务器hadoop102 | 服务器hadoop103 | 服务器hadoop104 |
| ----------- | ------------ | ------------ | ------------ |
| Flume(采集日志) | Flume        | Flume        |              |

采集日志的flume我们安装在102和103上，后续我们104上会安装消费kafka的flume，这边先不安装，后续等卡夫卡安装完毕后再安装104.



#### 1 Flume安装地址

1） Flume官网地址

<http://flume.apache.org/>

2）文档查看地址

<http://flume.apache.org/FlumeUserGuide.html>

这里多说一句，flume的文档是我看过英文文档里面可阅读性最好的，就算英文不好也能很快适应，点赞！

3）下载地址

http://archive.apache.org/dist/flume/  （**注意！！我们使用的是1.70版本。不要用其他版本，有可能会有兼容性问题**）

#### 2 安装部署

1）将apache-flume-1.7.0-bin.tar.gz上传到linux的/opt/software目录下

2）解压apache-flume-1.7.0-bin.tar.gz到/opt/module/目录下

```
[xzt@hadoop102 software]$ tar -zxvf apache-flume-1.7.0-bin.tar.gz -C /opt/module/
```

3）修改apache-flume-1.7.0-bin的名称为flume

```
[xzt@hadoop102 module]$ mv apache-flume-1.7.0-bin flume
```

4）将flume/conf下的flume-env.sh.template文件修改为flume-env.sh，并配置flume-env.sh文件

```
[xzt@hadoop102 conf]$ mv flume-env.sh.template flume-env.sh
```

```
[xzt@hadoop102 conf]$ vi flume-env.sh
```

```
export JAVA_HOME=/opt/module/jdk1.8.0_144  (根据你自己安装JDK的地址来填写)
```

5) 分发flume

```
[xzt@hadoop102 module]$ xsync flume/
```

### 3 Flume监控之Ganglia（可选）

ganglia 是用来监控flume运行情况的一个组件，一般用在flume集群搭建完之后，跑测试程序时用来监控flume集群的性能的，在这边有兴趣的同学可以尝试装一下，前提是你的机器性能不能太差（内存<16G）.

##### 1)   安装httpd服务与php

```
[xzt@hadoop102 flume]$ sudo yum -y install httpd php
```

##### 2)   安装其他依赖

```
[xzt@hadoop102 flume]$ sudo yum -y install rrdtool perl-rrdtool rrdtool-devel
```

```
[xzt@hadoop102 flume]$ sudo yum -y install apr-devel
```

##### 3)   安装ganglia

```
[xzt@hadoop102 flume]$ sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
```

```
[xzt@hadoop102 flume]$ sudo yum -y install ganglia-gmetad 
```

```
[xzt@hadoop102 flume]$ sudo yum -y install ganglia-web
```

```
[xzt@hadoop102 flume]$ sudo yum install -y ganglia-gmond
```

##### 4)   修改配置文件/etc/httpd/conf.d/ganglia.conf

```
[xzt@hadoop102 flume]$ sudo vim /etc/httpd/conf.d/ganglia.conf
```

**修改配置：**

```
# Ganglia monitoring system php web frontend
Alias /ganglia /usr/share/ganglia
<Location /ganglia>
  Order deny,allow
  Deny from all
  Allow from all
  # Allow from 127.0.0.1
  # Allow from ::1
  # Allow from .example.com
</Location>
```

****



##### 5)   修改配置文件/etc/ganglia/gmetad.conf

```
[xzt@hadoop102 flume]$ sudo vim /etc/ganglia/gmetad.conf
```

**修改为：**

```
data_source "hadoop102"192.168.1.102(ip根据你的情况填写)
```

##### 6)   修改配置文件/etc/ganglia/gmond.conf

```
[xzt@hadoop102 flume]$ sudo vim /etc/ganglia/gmond.conf 
```

**修改为：**



```
cluster {

 name = "hadoop102"

 owner = "unspecified"

 latlong = "unspecified"

  url= "unspecified"

}

udp_send_channel {

 #bind_hostname = yes # Highly recommended, soon to be default.

                       # This option tellsgmond to use a source address

                       # that resolves to themachine's hostname.  Without

                       # this, the metrics mayappear to come from any

                       # interface and the DNSnames associated with

                       # those IPs will be usedto create the RRDs.

  # mcast_join =239.2.11.71

  host = 192.168.1.102

 port = 8649

  ttl= 1

}

udp_recv_channel {

 # mcast_join = 239.2.11.71

 port = 8649

 bind = 192.168.1.102

 retry_bind = true

  #Size of the UDP buffer. If you are handling lots of metrics you really

  #should bump it up to e.g. 10MB or even higher.

  #buffer = 10485760

}
```



##### **7) **修改配置文件/etc/selinux/config

```
[xzt@hadoop102 flume]$ sudo vim /etc/selinux/config
```

```
# This file controls the state of SELinuxon the system.

# SELINUX= can take one of these threevalues:

#    enforcing - SELinux security policy is enforced.

#    permissive - SELinux prints warnings instead of enforcing.

#    disabled - No SELinux policy is loaded.

SELINUX=disabled

# SELINUXTYPE= can take one of these twovalues:

#    targeted - Targeted processes are protected,

#    mls - Multi Level Security protection.

SELINUXTYPE=targeted

```



**尖叫提示：selinux本次生效关闭必须重启，如果此时不想重启，可以临时生效之：**

```
[xzt@hadoop102 flume]$ sudo setenforce 0
```

##### 5)   启动ganglia

```
[xzt@hadoop102 flume]$ sudo service httpd start
```

```
[xzt@hadoop102 flume]$ sudo service gmetad start

```

```
[xzt@hadoop102 flume]$ sudo service gmond start
```

##### 6)   打开网页浏览ganglia页面

<http://192.168.1.102/ganglia>

尖叫提示：如果完成以上操作依然出现权限不足错误，请修改/var/lib/ganglia目录的权限：

```
[xzt@hadoop102 flume]$ sudo chmod -R 777 /var/lib/ganglia
```



##### 7）操作Flume测试监控



1)   修改/opt/module/flume/conf目录下的flume-env.sh配置：

```
JAVA_OPTS="-Dflume.monitoring.type=ganglia

-Dflume.monitoring.hosts=192.168.1.102:8649

-Xms100m

-Xmx200m"
```



2)   启动Flume任务

```
[xzt@hadoop102 flume]$ bin/flume-ng agent \

--conf conf/ \

--name a1 \

--conf-file job/flume-telnet-logger.conf \ (如果你是跟着文档走下来的，这块会报错，因为刚安装的没有job,你可以随便写一个案例来监控，替换掉flume-telnet-logger.conf)

-Dflume.root.logger==INFO,console \

-Dflume.monitoring.type=ganglia \

-Dflume.monitoring.hosts=192.168.1.102:8649

```

3) 发送数据观察ganglia监测图

```
[xzt@hadoop102 flume]$ telnet localhost 44444
```

![ganggia](https://github.com/xzt1995/Data-Warehouse/blob/master/img/ganggia.png)





### 4 flume 组件



#### 1）Source

##### （1）Taildir Source相比Exec Source、Spooling Directory Source的优势

TailDir Source：断点续传、多目录。Flume1.6以前需要自己自定义Source记录每次读取文件位置，实现断点续传。

Exec Source可以实时搜集数据，但是在Flume不运行或者Shell命令出错的情况下，数据将会丢失。

Spooling Directory Source 监控目录，不支持断点续传。

##### （2）batchSize大小如何设置？

答：Event 1K左右时，500-1000合适（默认为100）

#### 2）Channel

采用Kafka Channel，省去了Sink，提高了效率。



### 5 日志采集Flume配置



![日志采集flume配置](D:\Workspaces\Data-Warehouse\Data-Warehouse\img\日志采集flume配置.png)



Flume直接读log日志的数据，log日志的格式是app-yyyy-mm-dd.log。通过两个kafka channel 来连接kafka的不同topic。

这边我们要自定义一个ETL拦截器和一个类型区分拦截器，来对初始数据进行简单的清洗，并将启动日志和事件日志区分开，发往不同的topic。



#### 1 flume具体配置

（1）在/opt/module/flume/conf目录下创建file-flume-kafka.conf文件

```
[xzt@hadoop102 conf]$ vim file-flume-kafka.conf
```

  (2) 具体配置

```shell
# 组件定义
a1.sources=r1
a1.channels=c1 c2

# configure source
a1.sources.r1.type = TAILDIR
# 记录文件索引节点的目录，实现断点续传
a1.sources.r1.positionFile = /opt/module/flume/test/log_position.json
a1.sources.r1.channels = c1 c2 
# 监控的目录
a1.sources.r1.filegroups = f1 
a1.sources.r1.filegroups.f1 = /tmp/logs/app.+
a1.sources.r1.fileHeader = true

#interceptor 拦截器
a1.sources.r1.interceptors =  i1 i2
a1.sources.r1.interceptors.i1.type = com.xzt.flume.interceptor.LogETLInterceptor$Builder
a1.sources.r1.interceptors.i2.type = com.xzt.flume.interceptor.LogTypeInterceptor$Builder

#channels 选择器
a1.sources.r1.selector.type = multiplexing
a1.sources.r1.selector.header = topic
a1.sources.r1.selector.mapping.topic_start = c1
a1.sources.r1.selector.mapping.topic_event = c2

# configure channel
a1.channels.c1.type = org.apache.flume.channel.kafka.KafkaChannel
# kafka 集群
a1.channels.c1.kafka.bootstrap.servers = hadoop102:9092,hadoop103:9092,hadoop104:9092
# kafka topic
a1.channels.c1.kafka.topic = topic_start
# 默认是true , 会在解析完json后在前面加一个topic主题的前缀 ，这边我们不需要，否则到HIVE后还要将前缀去掉
a1.channels.c1.parseAsFlumeEvent = false
# kafka 消费者组
a1.channels.c1.kafka.consumer.group.id = flume-consumer

a1.channels.c2.type = org.apache.flume.channel.kafka.KafkaChannel
a1.channels.c2.kafka.bootstrap.servers = hadoop102:9092,hadoop103:9092,hadoop104:9092
a1.channels.c2.kafka.topic = topic_event
a1.channels.c2.parseAsFlumeEvent = false
a1.channels.c2.kafka.consumer.group.id = flume-consumer

```



（3）  分发到Hadoop103



#### 2 Flume的ETL和分类型拦截器

本项目中自定义了两个拦截器，分别是：ETL拦截器、日志类型区分拦截器。

ETL拦截器主要用于，过滤时间戳不合法和Json数据不完整的日志

日志类型区分拦截器主要用于，将启动日志和事件日志区分开来，方便发往Kafka的不同Topic。

工程已经放在了Data-Warehouse\jars\flume ， 可以用idea打开看一下是如何写的。

1 先定义一个类去实现org.apache.flume.interceptor.Interceptor;

2 重写四个方法

3 写一个内部静态类Builder方便后续启动



1）需要先将打好的包（flume-interceptor-1.0-SNAPSHOT.jar）放入到hadoop102的/opt/module/flume/lib文件夹下面。

2）分发到hadoop103、hadoop104

```
[xzt@hadoop102 lib]$ xsync flume-interceptor-1.0-SNAPSHOT.jar 
```

 3）启动flume

```
[xzt@hadoop102 flume]$ bin/flume-ng agent --name a1 --conf-file conf/file-flume-kafka.conf &
```





### 6 日志采集Flume启动停止脚本

1）在/home/xzt/bin目录下创建脚本f1.sh ,  在脚本中填写如下内容

```shell
#! /bin/bash

case $1 in
"start"){
       for i in hadoop102 hadoop103
       do
                echo " --------启动 $i 采集flume-------"
                ssh $i "nohup /opt/module/flume/bin/flume-ng agent --conf-file/opt/module/flume/conf/file-flume-kafka.conf --name a1-Dflume.root.logger=INFO,LOGFILE >/dev/null 2>&1 &"
       done
};; 
"stop"){
       for i in hadoop102 hadoop103
       do
                echo " --------停止 $i 采集flume-------"
                ssh $i"ps -ef | grep file-flume-kafka | grep -v grep |awk '{print $2}' | xargskill"
       done
};;
esac
```



说明1：nohup，该命令可以在你退出帐户/关闭终端之后继续运行相应的进程。nohup就是不挂起的意思，不挂断地运行命令。

说明2：/dev/null代表linux的空设备文件，所有往这个文件里面写入的内容都会丢失，俗称“黑洞”。这边是为了节省我们的磁盘空间，企业开发中可以留下这些日志。

标准输入0：从键盘获得输入 /proc/self/fd/0 

标准输出1：输出到屏幕（即控制台） /proc/self/fd/1 

错误输出2：输出到屏幕（即控制台） /proc/self/fd/2

2）增加脚本执行权限

```
[xzt@hadoop102 bin]$ chmod 777 f1.sh
```

3）f1集群启动脚本

```
[xzt@hadoop102 module]$ f1.sh start
```

4）f1集群停止脚本

```
[xzt@hadoop102 module]$ f1.sh stop
```


