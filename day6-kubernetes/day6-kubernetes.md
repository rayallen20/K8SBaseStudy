# day6-kubernetes草记

## 云原生简介

- 2004年开始,Google已在内部大规模地使用容器技术
- 2008年,Google将Cgroups合并进入了Linux内核
- 2013年,Docker项目正式发布
- 2014年,Kubernetes项目正式发布
- 2015年,由Google、Redhat以及微软等大型云计算厂商以及一些开源公司共同牵头成立了CNCF(Cloud Native Computing Foundation)云原生计算基金会
- 2017年,CNCF达到170个成员和14个基金项目
- 2018年,CNCF成立三周年有了195个成员,19个基金会项目和11个孵化项目

## 云原生定义

[云原生定义](https://github.com/cncf/toc/blob/main/DEFINITION.md#%E4%B8%AD%E6%96%87%E7%89%88%E6%9C%AC)

## 云原生技术栈

- 容器:以docker为代表的容器运行技术
- 服务网格:比如Service Mesh等
- 微服务:在微服务体系结构中,一个项目是由多个松耦合且可独立部署的较小组件或服务组成
- 不可变基础设施:不可变基础设施可以理解为一个应用运行所需要的基本运行需求,不可变最基本的就是指运行服务的服务器在完成部署后,就不在进行更改,比如镜像等
- 声明式API:描述应用程序的运行状态,并且由系统来决定如何来创建这个环境,例如声明一个pod,会有k8s执行创建并维持副本

## 云原生特征

- 符合12因素应用,12要素应用程序是一种构建应用程序的方法
- 面向微服务架构
- 自服务敏捷架构
- 基于API的协作
- 抗脆弱性

## 12因素引用

1. 基准代码:一份基准代码,多份部署(用同一个代码库进行版本控制,并可进行多次部署)
2. 依赖:显式地声明和隔离相互之间的依赖
3. 配置:在环境中存储配置
4. 后端服务:把后端服务当作一种附加资源
5. 构建,发布,运行:对程序执行构建或打包,并严格分离构建和运行
6. 进程:以一个或多个无状态进程运行应用
7. 端口绑定:通过端口绑定提供服务
8. 并发:通过进程模型进行扩展
9. 易处理:快速地启动,优雅地终止,最大程度上保持健壮性
10. 开发环境与线上环境等价:尽可能的保持开发,预发布,线上环境相同
11. 日志:将所有运行中进程和后端服务的输出流按照时间顺序统一收集存储和展示
12. 管理进程:一次性管理进程(数据备份等)应该和正常的常驻进程使用同样的运行环境

## 云原生景观图

[云原生景观图](https://landscape.cncf.io/)


## 云原生项目分类

![云原生项目分类](./img/云原生项目分类.png)

## Kubernetes简介

- Kubernetes最初源于谷歌内部的Borg,Borg是谷歌内部的大规模集群管理系统,负责对谷歌内部很多核心服务的调度和管理,Borg的目的是让用户能够不必操心资源管理的问题,让他们专注于自己的核心业务,并且做到跨多个数据中心的资源利用率最大化
- Borg主要由BorgMaster、Borglet、borgcfg和Scheduler组成

![Brog](./img/Brog.png)

[官网](https://kubernetes.io/zh/)

[项目地址](https://github.com/kubernetes/kubernetes)

## kubernetes组件简介

### kube-apiserver

[kube-apiserver](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-apiserver/)

Kubernetes API server提供了k8s各类资源对象的增删改查watch等HTTP Rest接口,这些对象包括pods、services、replicationcontrollers等,API Server为REST操作提供服务,并为集群的共享状态提供前端,所有其他组件都通过该前端进行交互

RESTful API:是REST风格的网络接口,REST描述的是在网络中client和server的一种交互形式

[REST](https://github.com/Arachni/arachni/wiki/REST-API):是一种软件架构风格,或者说是一种规范,其强调HTTP应当以资源为中心,并且规范了URI的风格,规范了HTTP请求动作(GET/PUT/POST/DELETE/HEAD/OPTIONS)的使用,具有对应的语义

![kubernetes组件](./img/kubernetes组件.png)

![访问流程](./img/访问流程.png)

- kube-apiserver端口默认值为6443,可通过启动参数"--secure-port"的值来修改默认值
- 默认IP地址为非本地(Non-Localhost)网络端口,通过启动参数"--bind-address"设置该值
- 该端口用于接收客户端、dashboard等外部HTTPS请求
- 用于基于Token文件或客户端证书及HTTP Base的认证
- 用于基于策略的授权

### kube-scheduler

[kube-scheduler](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-scheduler/)

kube-scheduler是一个控制面进程,负责将Pods指派到节点上

- 通过调度算法为待调度Pod列表的每个Pod从可用Node列表中选择一个最适合的Node,并将信息写入etcd中
- node节点上的kubelet通过API Server监听到kubernetes Scheduler产生的Pod绑定信息,然后获取对应的Pod清单,下载Image,并启动容器

调度策略:

1. 先排除不符合条件的节点
2. 在剩余的可用选出一个最符合条件的节点

- LeastRequestedPriority:优先从备选节点列表中选择资源消耗最小的节点(CPU+内存)
- CalculateNodeLabelPriority:优先选择含有指定Label的节点
- BalancedResourceAllocation:优先从备选节点列表中选择各项资源使用率最均衡的节点

- step1. 创建pod

![创建pod](./img/创建pod.png)

- step2. 过滤掉资源不足的节点

![过滤掉资源不足的节点](./img/过滤掉资源不足的节点.png)

- step3. 在剩余可用的节点中进行筛选

![在剩余可用节点中进行筛选](./img/在剩余可用节点中进行筛选.png)

- step4. 选中节点

![选中节点](./img/选中节点.png)

![调度流程](./img/调度流程.png)

![请求处理流程](./img/请求处理流程.png)

### kube-controller-manager

[kube-controller-manager](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-controller-manager/)

kube-controller-manager:Controller Manager还包括一些子控制器(副本控制器、节点控制器、命名空间控制器和服务账号控制器等),控制器作为集群内部的管理控制中心,负责集群内的Node、Pod副本、服务端点(Endpoint)、命名空间(Namespace)、服务账号(ServiceAccount)、资源定额(ResourceQuota)的管理,当某个Node意外宕机时,Controller Manager会及时发现并执行自动化修复流程,确保集群中的pod副本始终处于预期的工作状态

- controller-manager控制器每间隔5秒检查一次节点的状态
- 如果controller-manager控制器没有收到自节点的心跳,则将该node节点被标记为不可达
- controller-manager将在标记为无法访问之前等待40秒
- 如果该node节点被标记为无法访问后5分钟还没有恢复,controller-manager会删除当前node节点的所有pod并在其他可用节点重建这些pod

pod高可用机制:

- node monitor period:节点监视周期
- node monitor grace period:节点监视器宽限期
- pod eviction timeout:pod驱逐超时时间

![pod高可用机制](./img/pod高可用机制.png)

### kube-proxy

[kube-proxy](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-proxy/)

kube-proxy:Kubernetes网络代理运行在node上,它反映了node上Kubernetes API中定义的服务,并可以通过一组后端进行简单的TCP、UDP和SCTP流转发或者在一组后端进行循环TCP、UDP和SCTP转发,用户必须使用apiserver API创建一个服务来配置代理,其实就kube-proxy通过在主机上维护网络规则并执行连接转发来实现Kubernetes服务访问

kube-proxy运行在每个节点上,监听API Server中服务对象的变化,再通过管理IPtables或者IPVS规则来实现网络的转发

Kube-Proxy不同的版本可支持三种工作模式:

- UserSpace:k8s v1.1之前使用,k8s 1.2及以后就已经淘汰
- IPtables : k8s v1.1版本开始支持,1.2开始为默认
- IPVS: k8s v1.9引入,到v1.11成为正式版本,需要安装ipvsadm、ipset工具包和加载ip_vs内核模块

![kube-proxy](./img/kube-proxy.png)

![iptables模式](./img/iptables模式.png)

![ipvs模式](./img/ipvs模式.png)

IPVS相对IPtables效率会更高一些,使用IPVS模式需要在运行Kube-Proxy的节点上安装ipvsadm、ipset工具包和加载ip_vs内核模块,当Kube-Proxy以IPVS代理模式启动时,Kube-Proxy将验证节点上是否安装了IPVS模块,如果未安装,则Kube-Proxy将回退到IPtables代理模式

使用IPVS模式,Kube-Proxy会监视Kubernetes Service对象和Endpoints,调用宿主机内核Netlink接口以相应地创建IPVS规则并定期与Kubernetes Service对象Endpoints对象同步IPVS规则,以确保IPVS状态与期望一致,访问服务时,流量将被重定向到其中一个后端Pod,IPVS使用哈希表作为底层数据结构并在内核空间中工作,这意味着IPVS可以更快地重定向流量,并且在同步代理规则时具有更好的性能,此外,IPVS为负载均衡算法提供了更多选项,例如:rr(轮询调度)、lc(最小连接数)、dh(目标哈希)、sh(源哈希)、sed(最短期望延迟)、nq(不排队调度)等

[配置使用IPVS并指定调度算法](https://kubernetes.io/zh/docs/reference/config-api/kube-proxy-config.v1alpha1/#ClientConnectionConfiguration)

### kubelet

[kubelet](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kubelet/)

kubelet是运行在每个worker节点的代理组件,它会监视已分配给节点的pod,具体功能如下:

- 向master汇报node节点的状态信息
- 接受指令并在Pod中创建docker容器
- 准备Pod所需的数据卷
- 返回pod的运行状态
- 在node节点执行容器健康检查

![kubelet](./img/kubelet.png)

### kubectl

[kubectl](https://kubernetes.io/zh/docs/reference/kubectl/kubectl/)

是一个通过命令行对kubernetes集群进行管理的客户端工具

### etcd

[etcd](https://kubernetes.io/zh/docs/tasks/administer-cluster/configure-upgrade-etcd/)

etcd是CoreOS公司开发目前是Kubernetes默认使用的key-value数据存储系统,用于保存kubernetes的所有集群数据,etcd支持分布式集群功能,生产环境使用时需要为etcd数据提供定期备份机制

[官网](https://etcd.io/)

[github地址](https://github.com/etcd-io/etcd)

![etcd](./img/etcd.png)

### DNS

[DNS](https://kubernetes.io/zh/docs/tasks/administer-cluster/dns-custom-nameservers/)

DNS负责为整个集群提供DNS服务,从而实现服务之间的访问.kube-dns在kubernetes 1.18后不再支持,现在主要使用coredns

### Dashboard

[Dashboard](https://kubernetes.io/zh/docs/tasks/access-application-cluster/web-ui-dashboard/)

Dashboard是基于网页的Kubernetes用户界面,可以使用Dashboard获取运行在集群中的应用的概览信息,也可以创建或者修改Kubernetes资源(如Deployment,Job,DaemonSet等等),也可以对Deployment实现弹性伸缩、发起滚动升级、重启Pod或者使用向导创建新的应用

![dashboard](./img/dashboard.png)

## kubernetes高可用集群部署

### 服务器规划

|主机名|公网IP|内网IP|
|:-:|:-:|:-:|
|k8s-master-1|192.168.0.181|172.16.1.181|
|k8s-master-2|192.168.0.182|172.16.1.182|
|k8s-master-3|192.168.0.183|172.16.1.183|
|k8s-harbor-1|192.168.0.184|172.16.1.184|
|k8s-harbor-2|192.168.0.185|172.16.1.185|
|k8s-etcd-1|192.168.0.186|172.16.1.186|
|k8s-etcd-2|192.168.0.187|172.16.1.187|
|k8s-etcd-3|192.168.0.188|172.16.1.188|
|k8s-haproxy-1|192.168.0.189|172.16.1.189|
|k8s-haproxy-2|192.168.0.190|172.16.1.190|
|k8s-node-1|192.168.0.191|172.16.1.191|
|k8s-node-2|192.168.0.192|172.16.1.192|
|k8s-node-3|192.168.0.193|172.16.1.193|

其中:

- master节点为2C2G
- node节点的配置为4C4G
- 其他节点均为1C1G

### 部署

[部署工具kubeasz](https://github.com/easzlab/kubeasz)

实际上应该有一个节点单独用于部署.本例中部署节点和master节点混用,以便节省资源.

注意:

1. K8S集群内的所有节点要求时间同步,可以使用chrony做时间同步.Ubuntu20.04按如下方法设置:

	```
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	cat /etc/default/locale
	LANG=en_US.UTF-8
	LC_TIME=en_DK.UTF-8
	```

2. 确保在干净的系统上安装,不要使用曾经装过kubeadm或其他K8S发行版的环境.因为有可能出现端口冲突
3. 建议OS升级到新的稳定内核,结合阅读[内核升级文档](https://github.com/easzlab/kubeasz/blob/master/docs/guide/kernel_upgrade.md)
4. 在公有云上创建多主集群,请结合阅读[在公有云上部署kubeasz](https://github.com/easzlab/kubeasz/blob/master/docs/setup/kubeasz_on_public_cloud.md)
5. 运行etcd的节点个数要求为奇数

#### 部署harbor

- step1. 创建安装路径,上传安装包

```
root@k8s-harbor-1:~# mkdir -pv /apps
mkdir: created directory '/apps'
root@k8s-harbor-1:~# cd /apps/
root@k8s-harbor-1:/apps# ls
root@k8s-harbor-1:/apps# ls
docker-19.03.15-binary-install.tar.gz  harbor-offline-installer-v2.3.2.tgz
```

- step2. 安装docker

[安装docker操作](https://github.com/rayallen20/K8SBaseStudy/blob/master/day2-ceph-and-docker/day2-docker.md#123-ubuntu%E5%AE%89%E8%A3%85docker%E5%90%AF%E5%8A%A8%E5%B9%B6%E9%AA%8C%E8%AF%81%E6%9C%8D%E5%8A%A1)

- step3. 安装docker-compose

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

- step4. 安装harbor

	- step4.1 解压缩
	
	```
	root@k8s-harbor-1:/apps# tar xvf harbor-offline-installer-v2.3.2.tgz 
	harbor/harbor.v2.3.2.tar.gz
	harbor/prepare
	harbor/LICENSE
	harbor/install.sh
	harbor/common.sh
	harbor/harbor.yml.tmpl
	```

	- step4.2 生成自签名证书
	
	本次使用harbor需要使用https协议,故需要生成证书.
	
	```
	root@k8s-harbor-1:/apps/harbor# cd /root
	root@k8s-harbor-1:~# openssl rand -writerand .rnd
	root@k8s-harbor-1:~# cd /apps/harbor/
	root@k8s-harbor-1:/apps/harbor# mkdir certs
	root@k8s-harbor-1:/apps/harbor# cd certs/
	root@k8s-harbor-1:/apps/harbor/certs# openssl genrsa -out harbor-ca.key
	Generating RSA private key, 2048 bit long modulus (2 primes)
	.............+++++
	....................................................+++++
	e is 65537 (0x010001)
	root@k8s-harbor-1:/apps/harbor/certs# openssl req -x509 -new -nodes -key harbor-ca.key -subj "/CN=harbor.k8s.com" -days 7120 -out harbor-ca.crt
	root@k8s-harbor-1:/apps/harbor/certs# ls
	harbor-ca.crt  harbor-ca.key
	root@k8s-harbor-1:/apps/harbor/certs# pwd
	/apps/harbor/certs
	```
	
	此处生成`harbor-ca.key`时填写的域名,即后续修改harbor配置文件时要填写的域名.同时需要记住`harbor-ca.crt`和`harbor-ca.key`的路径,后续修改harbor配置文件时要填写.

	- step4.3 修改配置文件
	
	```
	root@k8s-harbor-1:/apps/harbor/certs# cd ..
	root@k8s-harbor-1:/apps/harbor# cp harbor.yml.tmpl harbor.yml
	root@k8s-harbor-1:/apps/harbor# vim harbor.yml
	root@k8s-harbor-1:/apps/harbor# cat harbor.yml
	# Configuration file of Harbor
	
	# The IP address or hostname to access admin UI and registry service.
	# DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
	hostname: harbor.k8s.com
	
	# http related config
	http:
	  # port for http, default is 80. If https enabled, this port will redirect to https port
	  port: 80
	
	# https related config
	https:
	  # https port for harbor, default is 443
	  port: 443
	  # The path of cert and key files for nginx
	  certificate: /apps/harbor/certs/harbor-ca.crt
	  private_key: /apps/harbor/certs/harbor-ca.key
	
	# # Uncomment following will enable tls communication between all harbor components
	# internal_tls:
	#   # set enabled to true means internal tls is enabled
	#   enabled: true
	#   # put your cert and key files on dir
	#   dir: /etc/harbor/tls/internal
	
	# Uncomment external_url if you want to enable external proxy
	# And when it enabled the hostname will no longer used
	# external_url: https://reg.mydomain.com:8433
	
	# The initial password of Harbor admin
	# It only works in first time to install harbor
	# Remember Change the admin password from UI after launching Harbor.
	harbor_admin_password: 123456
	
	# Harbor DB configuration
	database:
	  # The password for the root user of Harbor DB. Change this before any production use.
	  password: root123
	  # The maximum number of connections in the idle connection pool. If it <=0, no idle connections are retained.
	  max_idle_conns: 100
	  # The maximum number of open connections to the database. If it <= 0, then there is no limit on the number of open connections.
	  # Note: the default number of connections is 1024 for postgres of harbor.
	  max_open_conns: 900
	
	# The default data volume
	data_volume: /data/harbor
	...
	root@k8s-harbor-1:/apps/harbor# mkdir -pv /data/harbor
	mkdir: created directory '/data'
	mkdir: created directory '/data/harbor'
	root@k8s-harbor-1:/apps/harbor# 
	```
	
	对harbor的配置文件,需修改:
	
	1. `hostname`项,修改为生成自签名证书时的域名
	2. `https.cretificate`项,修改为公钥文件路径
	3. `https.private_key`项,修改为私钥文件路径
	4. `harbor_admin_password`:修改harbor的管理员登录密码
	5. `data_volume`:harbor存储镜像的路径

	- step4.4 安装harbor
	
	```
	root@k8s-harbor-1:/apps/harbor# ./install.sh --with-trivy
	
	[Step 0]: checking if docker is installed ...
	
	Note: docker version: 19.03.15
	
	[Step 1]: checking docker-compose is installed ...
	
	Note: docker-compose version: 1.24.1
	
	[Step 2]: loading Harbor images ...
	...
	[Step 5]: starting Harbor ...
	Creating network "harbor_harbor" with the default driver
	Creating harbor-log ... done
	Creating harbor-db     ... done
	Creating harbor-portal ... done
	Creating registry      ... done
	Creating registryctl   ... done
	Creating redis         ... done
	Creating trivy-adapter     ... done
	Creating harbor-core   ... done
	Creating harbor-jobservice ... done
	Creating nginx             ... done
	✔ ----Harbor has been installed and started successfully.----
	root@k8s-harbor-1:/apps/harbor# 
	```

- step5. 在`k8s-harbor-2`节点上,添加域名解析

```
root@k8s-harbor-2:/apps# vim /etc/hosts
root@k8s-harbor-2:/apps# cat /etc/hosts
127.0.0.1	localhost
127.0.1.1	ubuntu.example.local	ubuntu

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

# 192.168.0.184 harbor.k8s.com
172.16.1.184 harbor.k8s.com
```

- step6. `k8s-harbor-2`节点同步证书

在`k8s-harbor-2`节点上,安装docker和docker-compose,步骤同上.

创建公钥保存路径(注意:证书路径必须按如下路径创建):

```
root@k8s-harbor-2:/apps# mkdir -pv /etc/docker/certs.d/harbor.k8s.com
mkdir: created directory '/etc/docker/certs.d'
mkdir: created directory '/etc/docker/certs.d/harbor.k8s.com'
```

在`k8s-harbor-1`节点上发送公钥:

```
root@k8s-harbor-1:/apps/harbor# scp /apps/harbor/certs/harbor-ca.crt 192.168.0.185:/etc/docker/certs.d/harbor.k8s.com
The authenticity of host '192.168.0.185 (192.168.0.185)' can't be established.
ECDSA key fingerprint is SHA256:VH6te5reEMu455zs8p/cEdwGb0RoRgMFs2cSe15s85c.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.0.185' (ECDSA) to the list of known hosts.
root@192.168.0.185's password: 
harbor-ca.crt 
```

在`k8s-harbor-2`节点上重启docker

```
root@k8s-harbor-2:/apps# systemctl restart docker
```

- step7. 在`k8s-harbor-2`节点上登录

```
root@k8s-harbor-2:/apps# docker login harbor.k8s.com
Username: admin
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

- step8. 在harbor上创建仓库

![登录harbor](./img/登录harbor.png)

![创建项目](./img/创建项目.png)

- step9. `k8s-harbor-2`节点上测试上传镜像

```
root@k8s-harbor-2:/apps# docker pull centos:7.9.2009
7.9.2009: Pulling from library/centos
2d473b07cdd5: Pull complete 
Digest: sha256:c73f515d06b0fa07bb18d8202035e739a494ce760aa73129f60f4bf2bd22b407
Status: Downloaded newer image for centos:7.9.2009
docker.io/library/centos:7.9.2009
root@k8s-harbor-2:/apps# docker tag centos:7.9.2009 harbor.k8s.com/baseimages/centos:7.9.2009
root@k8s-harbor-2:/apps# docker push harbor.k8s.com/baseimages/centos:7.9.2009
The push refers to repository [harbor.k8s.com/baseimages/centos]
174f56854903: Pushed 
7.9.2009: digest: sha256:dead07b4d8ed7e29e98de0f4504d87e8880d4347859d839686a31da35a3b532f size: 529
```

![web查看镜像推送结果](./img/web查看镜像推送结果.png)

#### 部署keepalived

- step1. 在`k8s-haproxy-1`节点上安装`keepalived`和`haproxy`

```
root@k8s-haproxy-1:~# apt install keepalived haproxy -y
...
Created symlink /etc/systemd/system/multi-user.target.wants/keepalived.service → /lib/systemd/system/keepalived.service.
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
Processing triggers for dbus (1.12.2-1ubuntu1.2) ...
Processing triggers for rsyslog (8.32.0-1ubuntu4) ...
Processing triggers for ureadahead (0.100.0-21) ...
Processing triggers for libc-bin (2.27-3ubuntu1.2) ...
Processing triggers for systemd (237-3ubuntu10.42) ...
```

- step2. 配置`keepalived`

```
root@k8s-haproxy-1:~# cp /usr/share/doc/keepalived/samples/keepalived.conf.vrrp /etc/keepalived/keepalived.conf
root@k8s-haproxy-1:~# vim /etc/keepalived/keepalived.conf
root@k8s-haproxy-1:~# cat /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   notification_email {
     acassen
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 192.168.200.1
   smtp_connect_timeout 30
   router_id LVS_DEVEL
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    garp_master_delay 10
    smtp_alert
    virtual_router_id 56
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
	192.168.0.118 dev eth0 label eth0:0
	192.168.0.119 dev eth0 label eth0:1
	192.168.0.120 dev eth0 label eth0:2
	192.168.0.121 dev eth0 label eth0:3
    }
}
```

- step3. 重启`keepalived`并设置开机自启动

```
root@k8s-haproxy-1:~# systemctl restart keepalived.service 
root@k8s-haproxy-1:~# systemctl enable keepalived.service 
Synchronizing state of keepalived.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable keepalived
```

- step4. 查看本机网卡配置

```
root@k8s-haproxy-1:~# systemctl restart keepalived.service 
root@k8s-haproxy-1:~# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.189  netmask 255.255.255.0  broadcast 192.168.0.255
        inet6 fe80::20c:29ff:fec1:ff7a  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:c1:ff:7a  txqueuelen 1000  (Ethernet)
        RX packets 10348  bytes 3575760 (3.5 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 4895  bytes 472034 (472.0 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth0:0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.118  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:c1:ff:7a  txqueuelen 1000  (Ethernet)

eth0:1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.119  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:c1:ff:7a  txqueuelen 1000  (Ethernet)

eth0:2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.120  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:c1:ff:7a  txqueuelen 1000  (Ethernet)

eth0:3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.121  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:c1:ff:7a  txqueuelen 1000  (Ethernet)

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.16.1.189  netmask 255.255.255.0  broadcast 172.16.1.255
        inet6 fe80::20c:29ff:fec1:ff84  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:c1:ff:84  txqueuelen 1000  (Ethernet)
        RX packets 1  bytes 60 (60.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 19  bytes 1426 (1.4 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 115  bytes 11490 (11.4 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 115  bytes 11490 (11.4 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

- step5. 在`k8s-haproxy-2`节点上,安装`keepalived`和`haproxy`

本步骤操作step1

- step6. 在`k8s-haproxy-1`节点上将`keepalived`的配置传输给`k8s-haproxy-2`

```
root@k8s-haproxy-1:~# scp /etc/keepalived/keepalived.conf 192.168.0.190:/etc/keepalived/keepalived.conf
The authenticity of host '192.168.0.190 (192.168.0.190)' can't be established.
ECDSA key fingerprint is SHA256:VH6te5reEMu455zs8p/cEdwGb0RoRgMFs2cSe15s85c.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.0.190' (ECDSA) to the list of known hosts.
root@192.168.0.190's password: 
keepalived.conf                                                                                                                                                                                                                               100%  641     1.0MB/s   00:00    
```

- step7. 在`k8s-proxy-2`节点上调整配置文件中的优先级

keepalived是通过优先级来决定主备关系的,故需要调整`k8s-proxy-2`的优先级,使其称为备节点

```
root@k8s-haproxy-2:~# vim /etc/keepalived/keepalived.conf
root@k8s-haproxy-2:~# cat /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   notification_email {
     acassen
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 192.168.200.1
   smtp_connect_timeout 30
   router_id LVS_DEVEL
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    garp_master_delay 10
    smtp_alert
    virtual_router_id 56
    priority 80
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
	192.168.0.118 dev eth0 label eth0:0
	192.168.0.119 dev eth0 label eth0:1
	192.168.0.120 dev eth0 label eth0:2
	192.168.0.121 dev eth0 label eth0:3
    }
}
```

- step8. 在`k8s-proxy-2`节点上重启`keepalived`并设置为开机自启动

```
root@k8s-haproxy-2:~# systemctl restart keepalived.service
root@k8s-haproxy-2:~# systemctl enable keepalived.service 
Synchronizing state of keepalived.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable keepalived
```

#### 部署haproxy

- step1. 在`k8s-haproxy-1`节点上编辑haproxy的配置文件

```
root@k8s-haproxy-1:~# vim /etc/haproxy/haproxy.cfg 
root@k8s-haproxy-1:~# cat /etc/haproxy/haproxy.cfg
global
	log /dev/log	local0
	log /dev/log	local1 notice
	chroot /var/lib/haproxy
	stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
	stats timeout 30s
	user haproxy
	group haproxy
	daemon

	# Default SSL material locations
	ca-base /etc/ssl/certs
	crt-base /etc/ssl/private

	# Default ciphers to use on SSL-enabled listening sockets.
	# For more information, see ciphers(1SSL). This list is from:
	#  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
	# An alternative list with additional directives can be obtained from
	#  https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy
	ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
	ssl-default-bind-options no-sslv3

defaults
	log	global
	mode	http
	option	httplog
	option	dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
	errorfile 400 /etc/haproxy/errors/400.http
	errorfile 403 /etc/haproxy/errors/403.http
	errorfile 408 /etc/haproxy/errors/408.http
	errorfile 500 /etc/haproxy/errors/500.http
	errorfile 502 /etc/haproxy/errors/502.http
	errorfile 503 /etc/haproxy/errors/503.http
	errorfile 504 /etc/haproxy/errors/504.http

listen k8s-6443
  # bind的地址即keepalived配置的IP地址
  bind 192.168.0.118:6443
  mode tcp
  # server的IP地址即为kub-apiserver的节点地址 即本例中所有的k8s-master地址
  server k8s-master-1 192.168.0.181:6443 check inter 3s fall 3 rise 5
  server k8s-master-2 192.168.0.182:6443 check inter 3s fall 3 rise 5
  server k8s-master-3 192.168.0.183:6443 check inter 3s fall 3 rise 5
```

- step2. 重启`haproxy`并查看监听情况

```
root@k8s-haproxy-1:~# systemctl restart haproxy.service 
root@k8s-haproxy-1:~# ss -tnl
State                               Recv-Q                               Send-Q                                                                Local Address:Port                                                               Peer Address:Port                               
LISTEN                              0                                    128                                                                   192.168.0.118:6443                                                                    0.0.0.0:*                                  
LISTEN                              0                                    128                                                                   127.0.0.53%lo:53                                                                      0.0.0.0:*                                  
LISTEN                              0                                    128                                                                         0.0.0.0:22                                                                      0.0.0.0:*                                  
LISTEN                              0                                    128                                                                            [::]:22                                                                         [::]:*                                  
```

- step3. 设置`haproxy`开机自启动

```
root@k8s-haproxy-1:~# systemctl enable haproxy.service 
Synchronizing state of haproxy.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable haproxy
```

- step4. 将`haproxy.cfg`传输给`k8s-haproxy-2`节点

```
root@k8s-haproxy-1:~# scp /etc/haproxy/haproxy.cfg 192.168.0.190:/etc/haproxy/haproxy.cfg
root@192.168.0.190's password: 
haproxy.cfg   
```

- step5. 在`k8s-haproxy-2`节点上修改内核参数并使其生效

此时由于haproxy绑定的IP地址在`k8s-haproxy-1`上,故需要修改`k8s-haproxy-2`的内核参数,使`k8s-haproxy-2`允许监听本地不存在的socket.

```
root@k8s-haproxy-2:~# vim /etc/sysctl.conf 
root@k8s-haproxy-2:~# cat /etc/sysctl.conf
#
# /etc/sysctl.conf - Configuration file for setting system variables
# See /etc/sysctl.d/ for additional system variables.
# See sysctl.conf (5) for information.
#

net.ipv4.ip_nonlocal_bind = 1

...

```

该文件默认都是被注释上的,只需在文件头部的说明之后添加内容即可,该文件的其他内容均不需修改.

使配置的内核参数生效:

```
root@k8s-haproxy-2:~# sysctl -p
net.ipv4.ip_nonlocal_bind = 1
```

建议将该参数在`k8s-proxy-1`也配置上

- step6. 在`k8s-proxy-2`节点上重启`haproxy`并查看端口监听情况

```
root@k8s-haproxy-2:~# systemctl restart haproxy.service 
root@k8s-haproxy-2:~# ss -tnl
State                               Recv-Q                               Send-Q                                                                Local Address:Port                                                               Peer Address:Port                               
LISTEN                              0                                    128                                                                   127.0.0.53%lo:53                                                                      0.0.0.0:*                                  
LISTEN                              0                                    128                                                                         0.0.0.0:22                                                                      0.0.0.0:*                                  
LISTEN                              0                                    128                                                                   192.168.0.118:6443                                                                    0.0.0.0:*                                  
LISTEN                              0                                    128                                                                            [::]:22                                                                         [::]:*                                  

```

- step7. 在`k8s-proxy-2`节点上设置`haproxy`开机自启动

```
root@k8s-haproxy-2:~# systemctl enable haproxy.service 
Synchronizing state of haproxy.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable haproxy
```

注:如果虚拟机重启后harbor无法访问,切换到harbor的安装目录并执行`docker-compose -f docker-compose.yml up -d`即可

#### 部署kubernetes

此处将`k8s-master-1`节点作为部署节点,生产环境最好单独有一个部署节点.

- step1. 升级依赖并安装python2.7

```
root@k8s-master-1:~# apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y
...
root@k8s-master-1:~# apt-get install python2.7
...
ln -s /usr/bin/python2.7 /usr/bin/python
```

- step2. 安装ansible

```
root@k8s-master-1:~# curl -O https://bootstrap.pypa.io/pip/2.7/get-pip.py
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1863k  100 1863k    0     0  1355k      0  0:00:01  0:00:01 --:--:-- 1355k
root@k8s-master-1:~# python get-pip.py
DEPRECATION: Python 2.7 reached the end of its life on January 1st, 2020. Please upgrade your Python as Python 2.7 is no longer maintained. pip 21.0 will drop support for Python 2.7 in January 2021. More details about Python 2 support in pip can be found at https://pip.pypa.io/en/latest/development/release-process/#python-2-support pip 21.0 will remove support for this functionality.
Collecting pip<21.0
  Downloading pip-20.3.4-py2.py3-none-any.whl (1.5 MB)
     |████████████████████████████████| 1.5 MB 708 kB/s 
Collecting setuptools<45
  Downloading setuptools-44.1.1-py2.py3-none-any.whl (583 kB)
     |████████████████████████████████| 583 kB 6.1 MB/s 
Collecting wheel
  Downloading wheel-0.37.1-py2.py3-none-any.whl (35 kB)
Installing collected packages: pip, setuptools, wheel
Successfully installed pip-20.3.4 setuptools-44.1.1 wheel-0.37.1
root@k8s-master-1:~# pip install ansible -i https://mirrors.aliyun.com/pypi/simple/
...
Successfully built ansible ansible-core
Installing collected packages: MarkupSafe, jinja2, PyYAML, ipaddress, pycparser, cffi, six, enum34, cryptography, pyparsing, packaging, resolvelib, ansible-core, ansible
Successfully installed MarkupSafe-1.1.1 PyYAML-5.4.1 ansible-4.10.0 ansible-core-2.11.10 cffi-1.15.0 cryptography-3.3.2 enum34-1.1.10 ipaddress-1.0.23 jinja2-2.11.3 packaging-20.9 pycparser-2.21 pyparsing-2.4.7 resolvelib-0.5.5 six-1.16.0
```

- step3. 在ansible控制端配置免密码登录

	- step3.1 生成秘钥对
	
	```
	root@k8s-master-1:~# ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
	Generating public/private ed25519 key pair.
	Created directory '/root/.ssh'.
	Your identification has been saved in /root/.ssh/id_ed25519.
	Your public key has been saved in /root/.ssh/id_ed25519.pub.
	The key fingerprint is:
	SHA256:2W3umKfXa03inPgsU0BBCwd43fXvZvcTxkk7Mkct/M4 root@k8s-master-1
	The key's randomart image is:
	+--[ED25519 256]--+
	|         .o++o ..|
	|        . .oo.. .|
	|         . ...  o|
	|         o .. ooo|
	|        S . o.+o+|
	|           o ooXo|
	|            .*=BB|
	|           +*.*+E|
	|          ++.=+.o|
	+----[SHA256]-----+
	root@k8s-master-1:~# ssh-keygen -t rsa -b 2048 -N '' -f ~/.ssh/id_rsa
	Generating public/private rsa key pair.
	Your identification has been saved in /root/.ssh/id_rsa.
	Your public key has been saved in /root/.ssh/id_rsa.pub.
	The key fingerprint is:
	SHA256:5DkzxoFp5ZHp9mD2cBGp1+IdzOLC/JOKLXF851DpjRY root@k8s-master-1
	The key's randomart image is:
	+---[RSA 2048]----+
	|        oo.o     |
	|       =o.o      |
	|      +.+. = .   |
	|     . +Oo= E    |
	|       BSX * =   |
	|      ..*+B * .  |
	|       o + *     |
	|      .o  + .    |
	|      ..o. .     |
	+----[SHA256]-----+
	```

- 3.2 推送密钥

```
root@k8s-master-1:~# apt install sshpass -y
root@k8s-master-1:~# vit scp-key.sh
root@k8s-master-1:~# cat scp-key.sh 
#!/bin/bash

# 目标主机列表
IP="
192.168.0.181
192.168.0.182
192.168.0.183
192.168.0.186
192.168.0.187
192.168.0.188
192.168.0.191
192.168.0.192
192.168.0.193
"

for node in ${IP}; do
	sshpass -p 1 ssh-copy-id ${node} -o StrictHostKeyChecking=no
	if [$? -eq 0];then
		echo "${node} 密钥copy完成"
	else
		echo "${node} 密钥copy失败"
	fi
done
root@k8s-master-1:~# bash scp-key.sh 
```

- step4. 在部署节点编排K8S安装

- step4.1 下载安装脚本

	```
	root@k8s-master-1:~# export release=3.1.0
	root@k8s-master-1:~# wget https://github.com/easzlab/kubeasz/releases/download/${release}/ezdown
	--2022-04-10 04:02:11--  https://github.com/easzlab/kubeasz/releases/download/3.1.0/ezdown
	Resolving github.com (github.com)... 20.205.243.166
	Connecting to github.com (github.com)|20.205.243.166|:443... connected.
	HTTP request sent, awaiting response... 302 Found
	Location: https://objects.githubusercontent.com/github-production-release-asset-2e65be/110401202/750c6e00-a677-11eb-93b3-505f14b6a49a?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20220409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20220409T200211Z&X-Amz-Expires=300&X-Amz-Signature=853d48d66baae2c26e8160c04db0ecca291d3ae22175c76b489446e49e6f28eb&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=110401202&response-content-disposition=attachment%3B%20filename%3Dezdown&response-content-type=application%2Foctet-stream [following]
	--2022-04-10 04:02:11--  https://objects.githubusercontent.com/github-production-release-asset-2e65be/110401202/750c6e00-a677-11eb-93b3-505f14b6a49a?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20220409%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20220409T200211Z&X-Amz-Expires=300&X-Amz-Signature=853d48d66baae2c26e8160c04db0ecca291d3ae22175c76b489446e49e6f28eb&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=110401202&response-content-disposition=attachment%3B%20filename%3Dezdown&response-content-type=application%2Foctet-stream
	Resolving objects.githubusercontent.com (objects.githubusercontent.com)... 185.199.109.133, 185.199.108.133, 185.199.110.133, ...
	Connecting to objects.githubusercontent.com (objects.githubusercontent.com)|185.199.109.133|:443... connected.
	HTTP request sent, awaiting response... 200 OK
	Length: 15075 (15K) [application/octet-stream]
	Saving to: ‘ezdown’
	
	ezdown                                                              100%[===================================================================================================================================================================>]  14.72K  --.-KB/s    in 0.01s   
	
	2022-04-10 04:02:12 (1.16 MB/s) - ‘ezdown’ saved [15075/15075]
	
	root@k8s-master-1:~# chmod +x ./ezdown
	```

	- step4.2 修改安装脚本
	
	```
	root@k8s-master-1:~# vim ezdown 
	root@k8s-master-1:~# cat ezdown
	#!/bin/bash
	#--------------------------------------------------
	# This script is used for: 
	# 1. to download the scripts/binaries/images needed for installing a k8s cluster with kubeasz
	# 2. to run kubeasz in a container (optional)
	# @author:   gjmzj
	# @usage:    ./ezdown
	# @repo:     https://github.com/easzlab/kubeasz
	# @ref:      https://github.com/kubeasz/dockerfiles
	#--------------------------------------------------
	set -o nounset
	set -o errexit
	#set -o xtrace
	
	# default settings, can be overridden by cmd line options, see usage
	DOCKER_VER=19.03.15
	...
	```
	
	本案例中使用的docker版本为19.03.15,故修改变量`DOCKER_VER`,其他地方不动.

	- step4.3 执行脚本下载所需二进制包
	
	```
	root@k8s-master-1:~# bash ./ezdown -D
	...
	2022-04-10 04:40:18 INFO Action successed: download_all
	```

	上述脚本运行成功后,所有文件(kubeasz代码、二进制、离线镜像)均已整理好放入目录`/etc/kubeasz`

	- step4.4 创建集群配置实例
	
	```
	root@k8s-master-1:~# cd /etc/kubeasz/
	root@k8s-master-1:/etc/kubeasz# ./ezctl new k8s-my-cluster
	2022-04-10 04:45:37 DEBUG generate custom cluster files in /etc/kubeasz/clusters/k8s-my-cluster
	2022-04-10 04:45:37 DEBUG set version of common plugins
	2022-04-10 04:45:37 DEBUG cluster k8s-my-cluster: files successfully created.
	2022-04-10 04:45:37 INFO next steps 1: to config '/etc/kubeasz/clusters/k8s-my-cluster/hosts'
	2022-04-10 04:45:37 INFO next steps 2: to config '/etc/kubeasz/clusters/k8s-my-cluster/config.yml'
	```

	- step4.5 编辑集群主机信息配置文件
	
	```
	root@k8s-master-1:/etc/kubeasz# vim ./clusters/k8s-my-cluster/hosts 
	root@k8s-master-1:/etc/kubeasz# cat ./clusters/k8s-my-cluster/hosts
	# 'etcd' cluster should have odd member(s) (1,3,5,...)
	[etcd]
	192.168.0.186
	192.168.0.187
	192.168.0.188
	
	# master node(s)
	[kube_master]
	192.168.0.181
	192.168.0.182
	# 192.168.0.183
	
	# work node(s)
	[kube_node]
	192.168.0.191
	192.168.0.192
	# 192.168.0.193
	
	# [optional] harbor server, a private docker registry
	# 'NEW_INSTALL': 'true' to install a harbor server; 'false' to integrate with existed one
	[harbor]
	#192.168.1.8 NEW_INSTALL=false
	
	# [optional] loadbalance for accessing k8s from outside
	[ex_lb]
	# 189和190是haproxy的IP 118是keepalived中配置的IP
	192.168.0.189 LB_ROLE=backup EX_APISERVER_VIP=192.168.0.118 EX_APISERVER_PORT=8443
	192.168.0.190 LB_ROLE=master EX_APISERVER_VIP=192.168.0.118 EX_APISERVER_PORT=8443
	
	# [optional] ntp server for the cluster
	[chrony]
	#192.168.1.1
	
	[all:vars]
	# --------- Main Variables ---------------
	# Secure port for apiservers
	SECURE_PORT="6443"
	
	# Cluster container-runtime supported: docker, containerd
	CONTAINER_RUNTIME="docker"
	
	# Network plugins supported: calico, flannel, kube-router, cilium, kube-ovn
	CLUSTER_NETWORK="calico"
	
	# Service proxy mode of kube-proxy: 'iptables' or 'ipvs'
	PROXY_MODE="ipvs"
	
	# K8S Service CIDR, not overlap with node(host) networking
	# 该地址段不能与环境中任何现有网络冲突
	SERVICE_CIDR="10.100.0.0/16"
	
	# Cluster CIDR (Pod CIDR), not overlap with node(host) networking
	# 该地址段不能与环境中任何现有网络冲突
	CLUSTER_CIDR="10.200.0.0/16"
	
	# NodePort Range
	NODE_PORT_RANGE="30000-65000"
	
	# Cluster DNS Domain
	# K8S创建的service的后缀
	CLUSTER_DNS_DOMAIN="mycluster.local"
	
	# -------- Additional Variables (don't change the default value right now) ---
	# Binaries Directory
	bin_dir="/usr/local/bin"
	
	# Deploy Directory (kubeasz workspace)
	base_dir="/etc/kubeasz"
	
	# Directory for a specific cluster
	cluster_dir="{{ base_dir }}/clusters/k8s-my-cluster"
	
	# CA and other components cert/key Directory
	ca_dir="/etc/kubernetes/ssl"
	```
	
	此处将`k8s-master-3`和`k8s-node-3`注释掉是为了后边演示向集群中添加master节点和worker节点
	
	- step4.6 在`k8s-harbor-2`上拉取镜像并推送至harbor
	
	```
	root@k8s-harbor-2:/apps# docker pull easzlab/pause-amd64:3.4.1
	3.4.1: Pulling from easzlab/pause-amd64
	fac425775c9d: Pull complete 
	Digest: sha256:9ec1e780f5c0196af7b28f135ffc0533eddcb0a54a0ba8b32943303ce76fe70d
	Status: Downloaded newer image for easzlab/pause-amd64:3.4.1
	docker.io/easzlab/pause-amd64:3.4.1
	```
	
	打tag并推送:
	
	```
	root@k8s-harbor-2:/apps# docker tag easzlab/pause-amd64:3.4.1 harbor.k8s.com/baseimages/pause-amd64:3.4.1
	root@k8s-harbor-2:/apps# docker push harbor.k8s.com/baseimages/pause-amd64:3.4.1
	The push refers to repository [harbor.k8s.com/baseimages/pause-amd64]
	915e8870f7d1: Pushed 
	3.4.1: digest: sha256:9ec1e780f5c0196af7b28f135ffc0533eddcb0a54a0ba8b32943303ce76fe70d size: 526
	```
	
	- step4.7 编辑集群服务配置文件
	
	```
	root@k8s-master-1:/etc/kubeasz# vim ./clusters/k8s-my-cluster/config.yml 
	root@k8s-master-1:/etc/kubeasz# cat ./clusters/k8s-my-cluster/config.yml
	############################
	# prepare
	############################
	# 可选离线安装系统软件包 (offline|online)
	INSTALL_SOURCE: "online"
	
	# 可选进行系统安全加固 github.com/dev-sec/ansible-collection-hardening
	OS_HARDEN: false
	
	# 设置时间源服务器【重要：集群内机器时间必须同步】
	ntp_servers:
	  - "ntp1.aliyun.com"
	  - "time1.cloud.tencent.com"
	  - "0.cn.pool.ntp.org"
	
	# 设置允许内部时间同步的网络段，比如"10.0.0.0/8"，默认全部允许
	local_network: "0.0.0.0/0"
	
	
	############################
	# role:deploy
	############################
	# default: ca will expire in 100 years
	# default: certs issued by the ca will expire in 50 years
	CA_EXPIRY: "876000h"
	CERT_EXPIRY: "438000h"
	
	# kubeconfig 配置参数
	# 配置集群名称
	CLUSTER_NAME: "cluster1"
	CONTEXT_NAME: "context-{{ CLUSTER_NAME }}"
	
	
	############################
	# role:etcd
	############################
	# 设置不同的wal目录，可以避免磁盘io竞争，提高性能
	ETCD_DATA_DIR: "/var/lib/etcd"
	ETCD_WAL_DIR: ""
	
	
	############################
	# role:runtime [containerd,docker]
	############################
	# ------------------------------------------- containerd
	# [.]启用容器仓库镜像
	ENABLE_MIRROR_REGISTRY: true
	
	# [containerd]基础容器镜像
	SANDBOX_IMAGE: "harbor.k8s.com/baseimages/pause-amd64:3.4.1"
	
	# [containerd]容器持久化存储目录
	CONTAINERD_STORAGE_DIR: "/var/lib/containerd"
	
	# ------------------------------------------- docker
	# [docker]容器存储目录
	DOCKER_STORAGE_DIR: "/var/lib/docker"
	
	# [docker]开启Restful API
	ENABLE_REMOTE_API: false
	
	# [docker]信任的HTTP仓库
	INSECURE_REG: '["127.0.0.1/8","192.168.0.184"]'
	
	
	############################
	# role:kube-master
	############################
	# k8s 集群 master 节点证书配置，可以添加多个ip和域名（比如增加公网ip和域名）
	MASTER_CERT_HOSTS:
	  - "10.1.1.1"
	  - "k8s.test.io"
	  #- "www.test.com"
	
	# node 节点上 pod 网段掩码长度（决定每个节点最多能分配的pod ip地址）
	# 如果flannel 使用 --kube-subnet-mgr 参数，那么它将读取该设置为每个节点分配pod网段
	# https://github.com/coreos/flannel/issues/847
	NODE_CIDR_LEN: 24
	
	
	############################
	# role:kube-node
	############################
	# Kubelet 根目录
	KUBELET_ROOT_DIR: "/var/lib/kubelet"
	
	# node节点最大pod 数
	MAX_PODS: 300
	
	# 配置为kube组件（kubelet,kube-proxy,dockerd等）预留的资源量
	# 数值设置详见templates/kubelet-config.yaml.j2
	KUBE_RESERVED_ENABLED: "yes"
	
	# k8s 官方不建议草率开启 system-reserved, 除非你基于长期监控，了解系统的资源占用状况；
	# 并且随着系统运行时间，需要适当增加资源预留，数值设置详见templates/kubelet-config.yaml.j2
	# 系统预留设置基于 4c/8g 虚机，最小化安装系统服务，如果使用高性能物理机可以适当增加预留
	# 另外，集群安装时候apiserver等资源占用会短时较大，建议至少预留1g内存
	SYS_RESERVED_ENABLED: "no"
	
	# haproxy balance mode
	BALANCE_ALG: "roundrobin"
	
	
	############################
	# role:network [flannel,calico,cilium,kube-ovn,kube-router]
	############################
	# ------------------------------------------- flannel
	# [flannel]设置flannel 后端"host-gw","vxlan"等
	FLANNEL_BACKEND: "vxlan"
	DIRECT_ROUTING: false
	
	# [flannel] flanneld_image: "quay.io/coreos/flannel:v0.10.0-amd64"
	flannelVer: "v0.13.0-amd64"
	flanneld_image: "easzlab/flannel:{{ flannelVer }}"
	
	# [flannel]离线镜像tar包
	flannel_offline: "flannel_{{ flannelVer }}.tar"
	
	# ------------------------------------------- calico
	# [calico]设置 CALICO_IPV4POOL_IPIP=“off”,可以提高网络性能，条件限制详见 docs/setup/calico.md
	CALICO_IPV4POOL_IPIP: "Always"
	
	# [calico]设置 calico-node使用的host IP，bgp邻居通过该地址建立，可手工指定也可以自动发现
	IP_AUTODETECTION_METHOD: "can-reach={{ groups['kube_master'][0] }}"
	
	# [calico]设置calico 网络 backend: brid, vxlan, none
	CALICO_NETWORKING_BACKEND: "brid"
	
	# [calico]更新支持calico 版本: [v3.3.x] [v3.4.x] [v3.8.x] [v3.15.x]
	calico_ver: "v3.15.3"
	
	# [calico]calico 主版本
	calico_ver_main: "{{ calico_ver.split('.')[0] }}.{{ calico_ver.split('.')[1] }}"
	
	# [calico]离线镜像tar包
	calico_offline: "calico_{{ calico_ver }}.tar"
	
	# ------------------------------------------- cilium
	# [cilium]CILIUM_ETCD_OPERATOR 创建的 etcd 集群节点数 1,3,5,7...
	ETCD_CLUSTER_SIZE: 1
	
	# [cilium]镜像版本
	cilium_ver: "v1.4.1"
	
	# [cilium]离线镜像tar包
	cilium_offline: "cilium_{{ cilium_ver }}.tar"
	
	# ------------------------------------------- kube-ovn
	# [kube-ovn]选择 OVN DB and OVN Control Plane 节点，默认为第一个master节点
	OVN_DB_NODE: "{{ groups['kube_master'][0] }}"
	
	# [kube-ovn]离线镜像tar包
	kube_ovn_ver: "v1.5.3"
	kube_ovn_offline: "kube_ovn_{{ kube_ovn_ver }}.tar"
	
	# ------------------------------------------- kube-router
	# [kube-router]公有云上存在限制，一般需要始终开启 ipinip；自有环境可以设置为 "subnet"
	OVERLAY_TYPE: "full"
	
	# [kube-router]NetworkPolicy 支持开关
	FIREWALL_ENABLE: "true"
	
	# [kube-router]kube-router 镜像版本
	kube_router_ver: "v0.3.1"
	busybox_ver: "1.28.4"
	
	# [kube-router]kube-router 离线镜像tar包
	kuberouter_offline: "kube-router_{{ kube_router_ver }}.tar"
	busybox_offline: "busybox_{{ busybox_ver }}.tar"
	
	
	############################
	# role:cluster-addon
	############################
	# coredns 自动安装
	dns_install: "no"
	corednsVer: "1.8.0"
	ENABLE_LOCAL_DNS_CACHE: false
	dnsNodeCacheVer: "1.17.0"
	# 设置 local dns cache 地址
	LOCAL_DNS_CACHE: "169.254.20.10"
	
	# metric server 自动安装
	metricsserver_install: "no"
	metricsVer: "v0.3.6"
	
	# dashboard 自动安装
	dashboard_install: "no"
	dashboardVer: "v2.2.0"
	dashboardMetricsScraperVer: "v1.0.6"
	
	# ingress 自动安装
	ingress_install: "no"
	ingress_backend: "traefik"
	traefik_chart_ver: "9.12.3"
	
	# prometheus 自动安装
	prom_install: "no"
	prom_namespace: "monitor"
	prom_chart_ver: "12.10.6"
	
	# nfs-provisioner 自动安装
	nfs_provisioner_install: "no"
	nfs_provisioner_namespace: "kube-system"
	nfs_provisioner_ver: "v4.0.1"
	nfs_storage_class: "managed-nfs-storage"
	nfs_server: "192.168.1.10"
	nfs_path: "/data/nfs"
	
	############################
	# role:harbor
	############################
	# harbor version，完整版本号
	HARBOR_VER: "v2.1.3"
	HARBOR_DOMAIN: "harbor.yourdomain.com"
	HARBOR_TLS_PORT: 8443
	
	# if set 'false', you need to put certs named harbor.pem and harbor-key.pem in directory 'down'
	HARBOR_SELF_SIGNED_CERT: true
	
	# install extra component
	HARBOR_WITH_NOTARY: false
	HARBOR_WITH_TRIVY: false
	HARBOR_WITH_CLAIR: false
	HARBOR_WITH_CHARTMUSEUM: true
	```

	- step4.8 编辑`prepare.yml`

	注释掉`hosts.ex_lb`和`hosts.chrony`,表示不需要集群管理负载均衡和时间同步服务器
	
	```
	root@k8s-master-1:/etc/kubeasz# vim ./playbooks/01.prepare.yml 
	root@k8s-master-1:/etc/kubeasz# cat ./playbooks/01.prepare.yml
	# [optional] to synchronize system time of nodes with 'chrony' 
	- hosts:
	  - kube_master
	  - kube_node
	  - etcd
	    #- ex_lb
	    #- chrony
	  roles:
	  - { role: os-harden, when: "OS_HARDEN|bool" }
	  - { role: chrony, when: "groups['chrony']|length > 0" }
	
	# to create CA, kubeconfig, kube-proxy.kubeconfig etc.
	- hosts: localhost
	  roles:
	  - deploy
	
	# prepare tasks for all nodes
	- hosts:
	  - kube_master
	  - kube_node
	  - etcd
	  roles:
	  - prepare
	```

	- step4.9 正式安装:初始化
	
	```
	root@k8s-master-1:/etc/kubeasz# ./ezctl setup k8s-my-cluster 01
	...
	PLAY RECAP *********************************************************************************************************************************************************************************************************************************************************************
	192.168.0.181              : ok=25   changed=9    unreachable=0    failed=0    skipped=113  rescued=0    ignored=0   
	192.168.0.182              : ok=25   changed=10   unreachable=0    failed=0    skipped=113  rescued=0    ignored=0   
	192.168.0.186              : ok=21   changed=5    unreachable=0    failed=0    skipped=117  rescued=0    ignored=0   
	192.168.0.187              : ok=21   changed=5    unreachable=0    failed=0    skipped=117  rescued=0    ignored=0   
	192.168.0.188              : ok=21   changed=5    unreachable=0    failed=0    skipped=117  rescued=0    ignored=0   
	192.168.0.191              : ok=24   changed=9    unreachable=0    failed=0    skipped=114  rescued=0    ignored=0   
	192.168.0.192              : ok=24   changed=9    unreachable=0    failed=0    skipped=114  rescued=0    ignored=0   
	localhost                  : ok=34   changed=24   unreachable=0    failed=0    skipped=13   rescued=0    ignored=0   
	```

	- step4.10 安装etcd并检测
	
		- 安装
	
		```
		root@k8s-master-1:/etc/kubeasz# ./ezctl setup k8s-my-cluster 02
		PLAY RECAP *********************************************************************************************************************************************************************************************************************************************************************
		192.168.0.186              : ok=10   changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
		192.168.0.187              : ok=10   changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
		192.168.0.188              : ok=10   changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
		```
	
		etcd的配置在`/etc/systemd/system/etcd.service`中
	
		- 检测
			
		在`k8s-etcd-X`(即任何一个etcd节点)上执行:
			
		```
		root@k8s-etcd-1:~# vim etcd_heartbeat.sh 
		root@k8s-etcd-1:~# cat etcd_heartbeat.sh
		#!/bin/bash
			
		NODE_IPS="
		192.168.0.186
		192.168.0.187
		192.168.0.188
		"
			
		for ip in ${NODE_IPS};
		do ETCDCTL_API=3 /usr/local/bin/etcdctl --endpoints=https://${ip}:2379 --cacert=/etc/kubernetes/ssl/ca.pem --cert=/etc/kubernetes/ssl/etcd.pem --key=/etc/kubernetes/ssl/etcd-key.pem endpoint health;
		done
		root@k8s-etcd-1:~# bash etcd_heartbeat.sh 
		https://192.168.0.186:2379 is healthy: successfully committed proposal: took = 8.99946ms
		https://192.168.0.187:2379 is healthy: successfully committed proposal: took = 12.190637ms
		https://192.168.0.188:2379 is healthy: successfully committed proposal: took = 7.494615ms
		```
	
	- step4.11 在master和node节点上安装docker
	
		- 下发harbor证书:
		
			- 在`k8s-master-1`上创建证书目录:
			
			```
			root@k8s-master-1:/etc/kubeasz# mkdir -pv /etc/docker/certs.d/harbor.k8s.com/
			mkdir: created directory '/etc/docker'
			mkdir: created directory '/etc/docker/certs.d'
			mkdir: created directory '/etc/docker/certs.d/harbor.k8s.com/'
			```
		
			- 在`k8s-harbor-2`上下发证书:
			
			```
			root@k8s-harbor-2:~# scp /etc/docker/certs.d/harbor.k8s.com/harbor-ca.crt 192.168.0.181:/etc/docker/certs.d/harbor.k8s.com/
			The authenticity of host '192.168.0.181 (192.168.0.181)' can't be established.
			ECDSA key fingerprint is SHA256:VH6te5reEMu455zs8p/cEdwGb0RoRgMFs2cSe15s85c.
			Are you sure you want to continue connecting (yes/no)? yes
			Warning: Permanently added '192.168.0.181' (ECDSA) to the list of known hosts.
			root@192.168.0.181's password: 
			harbor-ca.crt                                 100% 1127   266.3KB/s   00:00    
			```
	
		- 在`k8s-master-1`上配置解析:
		
		```
		root@k8s-master-1:/etc/kubeasz# vim /etc/hosts
		root@k8s-master-1:/etc/kubeasz# cat /etc/hosts
		127.0.0.1	localhost
		127.0.1.1	ubuntu.example.local	ubuntu
		
		# The following lines are desirable for IPv6 capable hosts
		::1     localhost ip6-localhost ip6-loopback
		ff02::1 ip6-allnodes
		ff02::2 ip6-allrouters
		
		# 192.168.0.184 harbor.k8s.com
		172.16.1.184 harbor.k8s.com
		```
	
		- 编写脚本同步harbor证书给所有master节点和node节点:
		
		```
		root@k8s-master-1:~# vim scp-harbor-crt.sh
		root@k8s-master-1:~# cat scp-harbor-crt.sh
		#!/bin/bash
		
		# 目标主机列表 master节点和node节点的IP地址
		# 此处由于在k8s-master-1节点上已经登录过harbor且已经配置了域名解析
		# 故没有将该节点的IP地址写到IP中 如果有独立的部署节点 需将所有master节点和node节点的IP写到变量IP中
		IP="
		192.168.0.182
		192.168.0.183
		192.168.0.191
		192.168.0.192
		192.168.0.193
		"
		
		for node in ${IP}; do
			sshpass -p 1 ssh-copy-id ${node} -o StrictHostKeyChecking=no  
			echo "${node} 密钥copy完成"
			echo "${node} 密钥copy完成,准备环境初始化......"
			ssh ${node} "mkdir -p /etc/docker/certs.d/harbor.k8s.com"
			echo "Harbor证书目录创建成功"
			scp /etc/docker/certs.d/harbor.k8s.com/harbor-ca.crt ${node}:/etc/docker/certs.d/harbor.k8s.com/harbor-ca.crt
			echo "Harbor证书拷贝成功"
			ssh ${node} "echo "172.16.1.184 harbor.k8s.com" >> /etc/hosts"
			echo "host文件拷贝完成"
			# 以上节点均不需推送镜像至harbor 因此不需要拷贝harbor账号的认证文件
			# scp -r /root/.docker ${node}:/root/
			# echo "Harbor认证文件拷贝完成"
		done
		root@k8s-master-1:~# bash scp-harbor-crt.sh
		...
		/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
		/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
		
		/usr/bin/ssh-copy-id: WARNING: All keys were skipped because they already exist on the remote system.
				(if you think this is a mistake, you may want to use -f option)
		
		192.168.0.193 密钥copy完成
		192.168.0.193 密钥copy完成,准备环境初始化......
		Harbor证书目录创建成功
		harbor-ca.crt                                                                                                                                                                                                                                 100% 1127   913.3KB/s   00:00    
		Harbor证书拷贝成功
		host文件拷贝完成
		```

	- step4.12 安装docker
	
	```
	root@k8s-master-1:/etc/kubeasz# ./ezctl setup k8s-my-cluster 03
	...
	PLAY RECAP *********************************************************************************************************************************************************************************************************************************************************************
	192.168.0.181              : ok=8    changed=4    unreachable=0    failed=0    skipped=25   rescued=0    ignored=0   
	192.168.0.182              : ok=15   changed=12   unreachable=0    failed=0    skipped=15   rescued=0    ignored=0   
	192.168.0.191              : ok=15   changed=12   unreachable=0    failed=0    skipped=15   rescued=0    ignored=0   
	192.168.0.192              : ok=15   changed=12   unreachable=0    failed=0    skipped=15   rescued=0    ignored=0   
	```

	- step4.13 安装master
	
	master的配置文件:`/etc/kubeasz/playbooks/04.kube-master.yml`
	
	master角色任务:`/etc/kubeasz/roles/kube-master/tasks/main.yml`
	
	```
	root@k8s-master-1:/etc/kubeasz# ln -sv /bin/docker /usr/local/bin/
	'/usr/local/bin/docker' -> '/bin/docker'
	root@k8s-master-1:/etc/kubeasz# ./ezctl setup k8s-my-cluster 04
	...
	PLAY RECAP *********************************************************************************************************************************************************************************************************************************************************************
	192.168.0.181              : ok=58   changed=48   unreachable=0    failed=0    skipped=5    rescued=0    ignored=0   
	192.168.0.182              : ok=54   changed=45   unreachable=0    failed=0    skipped=5    rescued=0    ignored=0     
	```
	
	注:软链接那一步可以不做,不做的话安装组件`dnscache`时会报错,但实际上也并不会去用这个组件.所以这一步可以不做.
	
	验证:
	
	```
	root@k8s-master-1:/etc/kubeasz# kubectl get node
	NAME            STATUS                     ROLES    AGE   VERSION
	192.168.0.181   Ready,SchedulingDisabled   master   34m   v1.21.0
	192.168.0.182   Ready,SchedulingDisabled   master   34m   v1.21.0
	```
	
	此处只要`kubectl`命令能够通过验证即可
	
	- step4.14 安装node
	
		- 修改调度策略
		
		```
		root@k8s-master-1:/etc/kubeasz# vim roles/kube-node/templates/kube-proxy-config.yaml.j2 
		root@k8s-master-1:/etc/kubeasz# cat roles/kube-node/templates/kube-proxy-config.yaml.j2
		kind: KubeProxyConfiguration
		apiVersion: kubeproxy.config.k8s.io/v1alpha1
		bindAddress: {{ inventory_hostname }} 
		clientConnection:
		  kubeconfig: "/etc/kubernetes/kube-proxy.kubeconfig"
		clusterCIDR: "{{ CLUSTER_CIDR }}"
		conntrack:
		  maxPerCore: 32768
		  min: 131072
		  tcpCloseWaitTimeout: 1h0m0s
		  tcpEstablishedTimeout: 24h0m0s
		healthzBindAddress: {{ inventory_hostname }}:10256
		hostnameOverride: "{{ inventory_hostname }}"
		metricsBindAddress: {{ inventory_hostname }}:10249
		mode: "{{ PROXY_MODE }}"
		ipvs:
		  scheduler: wrr
		```
	
		此处可以不改,只是为了演示如何在安装前修改配置,故将ipvs的调度策略修改为`wrr`(加权轮询),默认为`rr`(轮询)
	
		- 安装
		
		```
		root@k8s-master-1:/etc/kubeasz# ./ezctl setup k8s-my-cluster 05
		...
		PLAY RECAP *********************************************************************************************************************************************************************************************************************************************************************
		192.168.0.191              : ok=41   changed=38   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
		192.168.0.192              : ok=39   changed=37   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
		```

		- 查看node情况
		
		```
		root@k8s-master-1:/etc/kubeasz# kubectl get node
		NAME            STATUS                     ROLES    AGE   VERSION
		192.168.0.181   Ready,SchedulingDisabled   master   46m   v1.21.0
		192.168.0.182   Ready,SchedulingDisabled   master   47m   v1.21.0
		192.168.0.191   Ready                      node     94s   v1.21.0
		192.168.0.192   Ready                      node     94s   v1.21.0
		```

	- step4.15 安装网络组件
	
		- 下载镜像并推送至harbor
		
		此处共需下载4个镜像:
		
		1. `calico/cni:v3.15.3`
		
			```
			root@k8s-master-1:/etc/kubeasz# docker pull calico/cni:v3.15.3
			v3.15.3: Pulling from calico/cni
			Digest: sha256:519e5c74c3c801ee337ca49b95b47153e01fd02b7d2797c601aeda48dc6367ff
			Status: Image is up to date for calico/cni:v3.15.3
			docker.io/calico/cni:v3.15.3
			root@k8s-master-1:/etc/kubeasz# docker tag calico/cni:v3.15.3 harbor.k8s.com/baseimages/calico-cni:v3.15.3
			root@k8s-master-1:/etc/kubeasz# docker push harbor.k8s.com/baseimages/calico-cni:v3.15.3
			The push refers to repository [harbor.k8s.com/baseimages/calico-cni]
			3fbbefdb79e9: Pushed 
			0cab240caf05: Pushed 
			ed578a6324e2: Pushed 
			e00099f6d86f: Pushed 
			0b954fdf8c09: Pushed 
			fa6b2b5f2343: Pushed 
			710ad749cc2d: Pushed 
			3e05a70dae71: Pushed 
			v3.15.3: digest: sha256:a559d264c7a75a7528560d11778dba2d3b55c588228aed99be401fd2baa9b607 size: 1997
			```
		
		2. `calico/pod2daemon-flexvol:v3.15.3`
		
			```
			root@k8s-master-1:/etc/kubeasz# docker pull calico/pod2daemon-flexvol:v3.15.3
			v3.15.3: Pulling from calico/pod2daemon-flexvol
			Digest: sha256:cec7a31b08ab5f9b1ed14053b91fd08be83f58ddba0577e9dabd8b150a51233f
			Status: Image is up to date for calico/pod2daemon-flexvol:v3.15.3
			docker.io/calico/pod2daemon-flexvol:v3.15.3
			root@k8s-master-1:/etc/kubeasz# docker tag calico/pod2daemon-flexvol:v3.15.3 harbor.k8s.com/baseimages/calico-pod2daemon-flexvol:v3.15.3
			root@k8s-master-1:/etc/kubeasz# docker push harbor.k8s.com/baseimages/calico-pod2daemon-flexvol:v3.15.3
			The push refers to repository [harbor.k8s.com/baseimages/calico-pod2daemon-flexvol]
			f0e55d2e215d: Pushed 
			7b2f85666007: Pushed 
			752045c6df15: Pushed 
			ca07dc9dd06e: Pushed 
			1d0352c1c217: Pushed 
			540c65dd0455: Pushed 
			48855504bcc3: Pushed 
			v3.15.3: digest: sha256:6bd1246d0ea1e573a6a050902995b1666ec0852339e5bda3051f583540361b55 size: 1788
			```
		
		3. `calico/node:v3.15.3`
		
			```
			root@k8s-master-1:/etc/kubeasz# docker pull calico/node:v3.15.3
			v3.15.3: Pulling from calico/node
			Digest: sha256:1d674438fd05bd63162d9c7b732d51ed201ee7f6331458074e3639f4437e34b1
			Status: Image is up to date for calico/node:v3.15.3
			docker.io/calico/node:v3.15.3
			root@k8s-master-1:/etc/kubeasz# docker tag calico/node:v3.15.3 harbor.k8s.com/baseimages/calico-node:v3.15.3
			root@k8s-master-1:/etc/kubeasz# docker push harbor.k8s.com/baseimages/calico-node:v3.15.3
			The push refers to repository [harbor.k8s.com/baseimages/calico-node]
			1ac5b96cb927: Pushed 
			2cccdddb8393: Pushed 
			4197e0310944: Pushed 
			1c96d3450595: Pushed 
			5b1e72320f72: Pushed 
			03e67b2525ff: Pushed 
			265153e4913a: Pushed 
			86cdf8f7c1fd: Pushed 
			a84575fecbb9: Pushed 
			566d20c1ccdf: Pushed 
			b76aa58f4c23: Pushed 
			v3.15.3: digest: sha256:988095dbe39d2066b1964aafaa4a302a1286b149a4a80c9a1eb85544f2a0cdd0 size: 3043
			```
		
		4. `calico/kube-controllers:v3.15.3`
		
			```
			root@k8s-master-1:/etc/kubeasz# docker pull calico/kube-controllers:v3.15.3
			v3.15.3: Pulling from calico/kube-controllers
			Digest: sha256:b88f0923b02090efcd13a2750da781622b6936df72d6c19885fcb2939647247b
			Status: Image is up to date for calico/kube-controllers:v3.15.3
			docker.io/calico/kube-controllers:v3.15.3
			root@k8s-master-1:/etc/kubeasz# docker tag calico/kube-controllers:v3.15.3 harbor.k8s.com/baseimages/calico-kube-controllers:v3.15.3
			root@k8s-master-1:/etc/kubeasz# docker push harbor.k8s.com/baseimages/calico-kube-controllers:v3.15.3
			The push refers to repository [harbor.k8s.com/baseimages/calico-kube-controllers]
			129d81d8b588: Pushed 
			938c6901f4e9: Pushed 
			5d936fb32531: Pushed 
			v3.15.3: digest: sha256:e59cc3287cb44ef835ef78e51b3835eabcddf8b16239a4d78abba5bb8260281c size: 948
			```
	
		- 修改网络组件的配置文件
		
		此处主要修改配置文件中的镜像地址,修改为自己搭建的harbor仓库地址
		
		```
		root@k8s-master-1:/etc/kubeasz# vim roles/calico/templates/calico-v3.15.yaml.j2 
		root@k8s-master-1:/etc/kubeasz# cat roles/calico/templates/calico-v3.15.yaml.j2
		---
		# Datastore: etcd, using Typha is redundant and not recommended.
		# Kubeasz uses cmd-line-way( kubectl create) to create etcd-secrets, see more in 'roles/calico/tasks/main.yml'
		
		# Source: calico/templates/calico-config.yaml
		# This ConfigMap is used to configure a self-hosted Calico installation.
		kind: ConfigMap
		apiVersion: v1
		metadata:
		  name: calico-config
		  namespace: kube-system
		data:
		  # Configure this with the location of your etcd cluster.
		  etcd_endpoints: "{{ ETCD_ENDPOINTS }}" 
		  # If you're using TLS enabled etcd uncomment the following.
		  # You must also populate the Secret below with these files.
		  etcd_ca: "/calico-secrets/etcd-ca"
		  etcd_cert: "/calico-secrets/etcd-cert"
		  etcd_key: "/calico-secrets/etcd-key"  
		
		  # Typha is disabled.
		  typha_service_name: "none"
		  # Configure the backend to use.
		  calico_backend: "{{ CALICO_NETWORKING_BACKEND }}"
		  # Configure the MTU to use for workload interfaces and tunnels.
		  # - If Wireguard is enabled, set to your network MTU - 60
		  # - Otherwise, if VXLAN or BPF mode is enabled, set to your network MTU - 50
		  # - Otherwise, if IPIP is enabled, set to your network MTU - 20
		  # - Otherwise, if not using any encapsulation, set to your network MTU.
		  veth_mtu: "1440"
		
		  # The CNI network configuration to install on each node. The special
		  # values in this config will be automatically populated.
		  cni_network_config: |-
		    {
		      "name": "k8s-pod-network",
		      "cniVersion": "0.3.1",
		      "plugins": [
		        {
		          "type": "calico",
		          "log_level": "info",
		          "etcd_endpoints": "{{ ETCD_ENDPOINTS }}",
		          "etcd_key_file": "/etc/calico/ssl/calico-key.pem",
		          "etcd_cert_file": "/etc/calico/ssl/calico.pem",
		          "etcd_ca_cert_file": "/etc/kubernetes/ssl/ca.pem",
		          "mtu": 1500,
		          "ipam": {
		              "type": "calico-ipam"
		          },
		          "policy": {
		              "type": "k8s"
		          },
		          "kubernetes": {
		              "kubeconfig": "/root/.kube/config"
		          }
		        },
		        {
		          "type": "portmap",
		          "snat": true,
		          "capabilities": {"portMappings": true}
		        },
		        {
		          "type": "bandwidth",
		          "capabilities": {"bandwidth": true}
		        }
		      ]
		    }
		
		---
		# Source: calico/templates/calico-kube-controllers-rbac.yaml
		
		# Include a clusterrole for the kube-controllers component,
		# and bind it to the calico-kube-controllers serviceaccount.
		kind: ClusterRole
		apiVersion: rbac.authorization.k8s.io/v1
		metadata:
		  name: calico-kube-controllers
		rules:
		  # Pods are monitored for changing labels.
		  # The node controller monitors Kubernetes nodes.
		  # Namespace and serviceaccount labels are used for policy.
		  - apiGroups: [""]
		    resources:
		      - pods
		      - nodes
		      - namespaces
		      - serviceaccounts
		    verbs:
		      - watch
		      - list
		      - get
		  # Watch for changes to Kubernetes NetworkPolicies.
		  - apiGroups: ["networking.k8s.io"]
		    resources:
		      - networkpolicies
		    verbs:
		      - watch
		      - list
		---
		kind: ClusterRoleBinding
		apiVersion: rbac.authorization.k8s.io/v1
		metadata:
		  name: calico-kube-controllers
		roleRef:
		  apiGroup: rbac.authorization.k8s.io
		  kind: ClusterRole
		  name: calico-kube-controllers
		subjects:
		- kind: ServiceAccount
		  name: calico-kube-controllers
		  namespace: kube-system
		---
		
		---
		# Source: calico/templates/calico-node-rbac.yaml
		# Include a clusterrole for the calico-node DaemonSet,
		# and bind it to the calico-node serviceaccount.
		kind: ClusterRole
		apiVersion: rbac.authorization.k8s.io/v1
		metadata:
		  name: calico-node
		rules:
		  # The CNI plugin needs to get pods, nodes, and namespaces.
		  - apiGroups: [""]
		    resources:
		      - pods
		      - nodes
		      - namespaces
		    verbs:
		      - get
		  - apiGroups: [""]
		    resources:
		      - endpoints
		      - services
		    verbs:
		      # Used to discover service IPs for advertisement.
		      - watch
		      - list
		  # Pod CIDR auto-detection on kubeadm needs access to config maps.
		  - apiGroups: [""]
		    resources:
		      - configmaps
		    verbs:
		      - get
		  - apiGroups: [""]
		    resources:
		      - nodes/status
		    verbs:
		      # Needed for clearing NodeNetworkUnavailable flag.
		      - patch
		
		---
		apiVersion: rbac.authorization.k8s.io/v1
		kind: ClusterRoleBinding
		metadata:
		  name: calico-node
		roleRef:
		  apiGroup: rbac.authorization.k8s.io
		  kind: ClusterRole
		  name: calico-node
		subjects:
		- kind: ServiceAccount
		  name: calico-node
		  namespace: kube-system
		
		---
		# Source: calico/templates/calico-node.yaml
		# This manifest installs the calico-node container, as well
		# as the CNI plugins and network config on
		# each master and worker node in a Kubernetes cluster.
		kind: DaemonSet
		apiVersion: apps/v1
		metadata:
		  name: calico-node
		  namespace: kube-system
		  labels:
		    k8s-app: calico-node
		spec:
		  selector:
		    matchLabels:
		      k8s-app: calico-node
		  updateStrategy:
		    type: RollingUpdate
		    rollingUpdate:
		      maxUnavailable: 1
		  template:
		    metadata:
		      labels:
		        k8s-app: calico-node
		    spec:
		      nodeSelector:
		        kubernetes.io/os: linux
		      hostNetwork: true
		      tolerations:
		        # Make sure calico-node gets scheduled on all nodes.
		        - effect: NoSchedule
		          operator: Exists
		        # Mark the pod as a critical add-on for rescheduling.
		        - key: CriticalAddonsOnly
		          operator: Exists
		        - effect: NoExecute
		          operator: Exists
		      serviceAccountName: calico-node
		      # Minimize downtime during a rolling upgrade or deletion; tell Kubernetes to do a "force
		      # deletion": https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods.
		      terminationGracePeriodSeconds: 0
		      priorityClassName: system-node-critical
		      initContainers:
		        # This container installs the CNI binaries
		        # and CNI network config file on each node.
		        - name: install-cni
		          image: harbor.k8s.com/baseimages/calico-cni:v3.15.3
		          command: ["/install-cni.sh"]
		          env:
		            # Name of the CNI config file to create.
		            - name: CNI_CONF_NAME
		              value: "10-calico.conflist"
		            # The CNI network config to install on each node.
		            - name: CNI_NETWORK_CONFIG
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: cni_network_config
		            # The location of the etcd cluster.
		            - name: ETCD_ENDPOINTS
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: etcd_endpoints
		            # CNI MTU Config variable
		            - name: CNI_MTU
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: veth_mtu
		            # Prevents the container from sleeping forever.
		            - name: SLEEP
		              value: "false"
		          volumeMounts:
		            - mountPath: /host/opt/cni/bin
		              name: cni-bin-dir
		            - mountPath: /host/etc/cni/net.d
		              name: cni-net-dir
		            - mountPath: /calico-secrets
		              name: etcd-certs
		          securityContext:
		            privileged: true
		        # Adds a Flex Volume Driver that creates a per-pod Unix Domain Socket to allow Dikastes
		        # to communicate with Felix over the Policy Sync API.
		        - name: flexvol-driver
		          image: harbor.k8s.com/baseimages/calico-pod2daemon-flexvol:v3.15.3
		          volumeMounts:
		          - name: flexvol-driver-host
		            mountPath: /host/driver
		          securityContext:
		            privileged: true
		      containers:
		        # Runs calico-node container on each Kubernetes node. This
		        # container programs network policy and routes on each
		        # host.
		        - name: calico-node
		          image: harbor.k8s.com/baseimages/calico-node:v3.15.3
		          env:
		            # The location of the etcd cluster.
		            - name: ETCD_ENDPOINTS
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: etcd_endpoints
		            # Location of the CA certificate for etcd.
		            - name: ETCD_CA_CERT_FILE
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: etcd_ca
		            # Location of the client key for etcd.
		            - name: ETCD_KEY_FILE
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: etcd_key
		            # Location of the client certificate for etcd.
		            - name: ETCD_CERT_FILE
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: etcd_cert
		            # Set noderef for node controller.
		            - name: CALICO_K8S_NODE_REF
		              valueFrom:
		                fieldRef:
		                  fieldPath: spec.nodeName
		            # Choose the backend to use.
		            - name: CALICO_NETWORKING_BACKEND
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: calico_backend
		            # Cluster type to identify the deployment type
		            - name: CLUSTER_TYPE
		              value: "k8s,bgp"
		            # Auto-detect the BGP IP address.
		            - name: IP
		              value: "autodetect"
		            - name: IP_AUTODETECTION_METHOD
		              value: "{{ IP_AUTODETECTION_METHOD }}"
		            # Enable IPIP
		{% if CALICO_NETWORKING_BACKEND == "brid" %}
		            - name: CALICO_IPV4POOL_IPIP
		              value: "{{ CALICO_IPV4POOL_IPIP }}"
		{% endif %}
		            # Enable or Disable VXLAN on the default IP pool.
		{% if CALICO_NETWORKING_BACKEND == "vxlan" %}
		            - name: CALICO_IPV4POOL_VXLAN
		              value: "Never"
		{% endif %}
		            # Set MTU for tunnel device used if ipip is enabled
		            - name: FELIX_IPINIPMTU
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: veth_mtu
		            # Set MTU for the VXLAN tunnel device.
		            - name: FELIX_VXLANMTU
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: veth_mtu
		            # Set MTU for the Wireguard tunnel device.
		            - name: FELIX_WIREGUARDMTU
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: veth_mtu
		            # The default IPv4 pool to create on startup if none exists. Pod IPs will be
		            # chosen from this range. Changing this value after installation will have
		            # no effect. This should fall within `--cluster-cidr`.
		            - name: CALICO_IPV4POOL_CIDR
		              value: "{{ CLUSTER_CIDR }}"
		            # Disable file logging so `kubectl logs` works.
		            - name: CALICO_DISABLE_FILE_LOGGING
		              value: "true"
		            # Set Felix endpoint to host default action to ACCEPT.
		            - name: FELIX_DEFAULTENDPOINTTOHOSTACTION
		              value: "ACCEPT"
		            # Disable IPv6 on Kubernetes.
		            - name: FELIX_IPV6SUPPORT
		              value: "false"
		            # Set Felix logging to "info"
		            - name: FELIX_LOGSEVERITYSCREEN
		              value: "warning"
		            - name: FELIX_HEALTHENABLED
		              value: "true"
		            # Set Kubernetes NodePorts: If services do use NodePorts outside Calico’s expected range,
		            # Calico will treat traffic to those ports as host traffic instead of pod traffic.
		            - name: FELIX_KUBENODEPORTRANGES
		              value: "{{ NODE_PORT_RANGE.split('-')[0] }}:{{ NODE_PORT_RANGE.split('-')[1] }}"
		            - name: FELIX_PROMETHEUSMETRICSENABLED
		              value: "false"
		          securityContext:
		            privileged: true
		          resources:
		            requests:
		              cpu: 250m
		          livenessProbe:
		            exec:
		              command:
		              - /bin/calico-node
		              - -felix-live
		{% if CALICO_NETWORKING_BACKEND == "brid" %}
		              - -bird-live
		{% endif %}
		            periodSeconds: 10
		            initialDelaySeconds: 10
		            failureThreshold: 6
		          readinessProbe:
		            exec:
		              command:
		              - /bin/calico-node
		              - -felix-ready
		{% if CALICO_NETWORKING_BACKEND == "brid" %}
		              - -bird-ready
		{% endif %}
		            periodSeconds: 10
		          volumeMounts:
		            - mountPath: /lib/modules
		              name: lib-modules
		              readOnly: true
		            - mountPath: /run/xtables.lock
		              name: xtables-lock
		              readOnly: false
		            - mountPath: /var/run/calico
		              name: var-run-calico
		              readOnly: false
		            - mountPath: /var/lib/calico
		              name: var-lib-calico
		              readOnly: false
		            - mountPath: /calico-secrets
		              name: etcd-certs
		            - name: policysync
		              mountPath: /var/run/nodeagent
		      volumes:
		        # Used by calico-node.
		        - name: lib-modules
		          hostPath:
		            path: /lib/modules
		        - name: var-run-calico
		          hostPath:
		            path: /var/run/calico
		        - name: var-lib-calico
		          hostPath:
		            path: /var/lib/calico
		        - name: xtables-lock
		          hostPath:
		            path: /run/xtables.lock
		            type: FileOrCreate
		        # Used to install CNI.
		        - name: cni-bin-dir
		          hostPath:
		            path: {{ bin_dir }}
		        - name: cni-net-dir
		          hostPath:
		            path: /etc/cni/net.d
		        # Mount in the etcd TLS secrets with mode 400.
		        # See https://kubernetes.io/docs/concepts/configuration/secret/
		        - name: etcd-certs
		          secret:
		            secretName: calico-etcd-secrets
		            defaultMode: 0400
		        # Used to create per-pod Unix Domain Sockets
		        - name: policysync
		          hostPath:
		            type: DirectoryOrCreate
		            path: /var/run/nodeagent
		        # Used to install Flex Volume Driver
		        - name: flexvol-driver-host
		          hostPath:
		            type: DirectoryOrCreate
		            path: /usr/libexec/kubernetes/kubelet-plugins/volume/exec/nodeagent~uds
		---
		
		apiVersion: v1
		kind: ServiceAccount
		metadata:
		  name: calico-node
		  namespace: kube-system
		
		---
		# Source: calico/templates/calico-kube-controllers.yaml
		# See https://github.com/projectcalico/kube-controllers
		apiVersion: apps/v1
		kind: Deployment
		metadata:
		  name: calico-kube-controllers
		  namespace: kube-system
		  labels:
		    k8s-app: calico-kube-controllers
		spec:
		  # The controllers can only have a single active instance.
		  replicas: 1
		  selector:
		    matchLabels:
		      k8s-app: calico-kube-controllers
		  strategy:
		    type: Recreate
		  template:
		    metadata:
		      name: calico-kube-controllers
		      namespace: kube-system
		      labels:
		        k8s-app: calico-kube-controllers
		    spec:
		      nodeSelector:
		        kubernetes.io/os: linux
		      tolerations:
		        # Mark the pod as a critical add-on for rescheduling.
		        - key: CriticalAddonsOnly
		          operator: Exists
		        - key: node-role.kubernetes.io/master
		          effect: NoSchedule
		      serviceAccountName: calico-kube-controllers
		      priorityClassName: system-cluster-critical
		      # The controllers must run in the host network namespace so that
		      # it isn't governed by policy that would prevent it from working.
		      hostNetwork: true
		      containers:
		        - name: calico-kube-controllers
		          image: harbor.k8s.com/baseimages/calico-kube-controllers:v3.15.3
		          env:
		            # The location of the etcd cluster.
		            - name: ETCD_ENDPOINTS
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: etcd_endpoints
		            # Location of the CA certificate for etcd.
		            - name: ETCD_CA_CERT_FILE
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: etcd_ca
		            # Location of the client key for etcd.
		            - name: ETCD_KEY_FILE
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: etcd_key
		            # Location of the client certificate for etcd.
		            - name: ETCD_CERT_FILE
		              valueFrom:
		                configMapKeyRef:
		                  name: calico-config
		                  key: etcd_cert
		            # Choose which controllers to run.
		            - name: ENABLED_CONTROLLERS
		              value: policy,namespace,serviceaccount,workloadendpoint,node
		          volumeMounts:
		            # Mount in the etcd TLS secrets.
		            - mountPath: /calico-secrets
		              name: etcd-certs
		          readinessProbe:
		            exec:
		              command:
		              - /usr/bin/check-status
		              - -r
		      volumes:
		        # Mount in the etcd TLS secrets with mode 400.
		        # See https://kubernetes.io/docs/concepts/configuration/secret/
		        - name: etcd-certs
		          secret:
		            secretName: calico-etcd-secrets
		            defaultMode: 0400
		
		---
		
		apiVersion: v1
		kind: ServiceAccount
		metadata:
		  name: calico-kube-controllers
		  namespace: kube-system
		```

		- 安装
		
		```
		root@k8s-master-1:/etc/kubeasz# ./ezctl setup k8s-my-cluster 06
		...
		PLAY RECAP *********************************************************************************************************************************************************************************************************************************************************************
		192.168.0.181              : ok=17   changed=15   unreachable=0    failed=0    skipped=51   rescued=0    ignored=0   
		192.168.0.182              : ok=12   changed=10   unreachable=0    failed=0    skipped=40   rescued=0    ignored=0   
		192.168.0.191              : ok=12   changed=10   unreachable=0    failed=0    skipped=40   rescued=0    ignored=0   
		192.168.0.192              : ok=12   changed=11   unreachable=0    failed=0    skipped=40   rescued=0    ignored=0  
		```
		
		- 验证
		
		```
		root@k8s-node-2:~# calicoctl node status
		Calico process is running.
		
		IPv4 BGP status
		+---------------+-------------------+-------+----------+-------------+
		| PEER ADDRESS  |     PEER TYPE     | STATE |  SINCE   |    INFO     |
		+---------------+-------------------+-------+----------+-------------+
		| 192.168.0.191 | node-to-node mesh | up    | 08:25:44 | Established |
		| 192.168.0.181 | node-to-node mesh | up    | 08:26:01 | Established |
		| 192.168.0.182 | node-to-node mesh | up    | 08:26:03 | Established |
		+---------------+-------------------+-------+----------+-------------+
		
		IPv6 BGP status
		No IPv6 peers found.
		```	

		- 测试
		
		尝试在同一个node节点上创建几个pod,查看创建出来的pod是否分布在不同的node上
		
		```
		root@k8s-node-2:~# kubectl run net-test1 --image=harbor.k8s.com/baseimages/alpine:latest sleep 300000
		pod/net-test1 created
		root@k8s-node-2:~# kubectl run net-test2 --image=harbor.k8s.com/baseimages/alpine:latest sleep 300000
		pod/net-test2 created
		root@k8s-node-2:~# kubectl run net-test3 --image=harbor.k8s.com/baseimages/alpine:latest sleep 300000
		pod/net-test3 created
		root@k8s-node-2:~# kubectl get pod -A -o wide
		NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE   IP              NODE            NOMINATED NODE   READINESS GATES
		default       net-test1                                  1/1     Running   0          24s   10.200.140.65   192.168.0.192   <none>           <none>
		default       net-test2                                  1/1     Running   0          19s   10.200.140.66   192.168.0.192   <none>           <none>
		default       net-test3                                  1/1     Running   0          15s   10.200.109.65   192.168.0.191   <none>           <none>
		kube-system   calico-kube-controllers-75b57c64c6-kjgxg   1/1     Running   0          11m   192.168.0.191   192.168.0.191   <none>           <none>
		kube-system   calico-node-8s9f4                          1/1     Running   0          11m   192.168.0.191   192.168.0.191   <none>           <none>
		kube-system   calico-node-bmwj8                          1/1     Running   0          11m   192.168.0.182   192.168.0.182   <none>           <none>
		kube-system   calico-node-kjqxq                          1/1     Running   0          11m   192.168.0.192   192.168.0.192   <none>           <none>
		kube-system   calico-node-mqzqb                          1/1     Running   0          11m   192.168.0.181   192.168.0.181   <none>           <none>
		```

		可以看到,`net-test1`和`net-test2`运行在了`k8s-node-2`上,`net-test3`运行在了`k8s-node-1`上.

		进入一个容器,尝试ping其他容器以及ping外网的IP地址
		
		```
		root@k8s-node-2:~# kubectl exec -it net-test2 sh
		kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
		/ # ping 10.200.109.65
		PING 10.200.109.65 (10.200.109.65): 56 data bytes
		64 bytes from 10.200.109.65: seq=0 ttl=62 time=0.932 ms
		64 bytes from 10.200.109.65: seq=1 ttl=62 time=1.785 ms
		^C
		--- 10.200.109.65 ping statistics ---
		2 packets transmitted, 2 packets received, 0% packet loss
		round-trip min/avg/max = 0.932/1.358/1.785 ms
		/ # ping 10.200.140.65
		PING 10.200.140.65 (10.200.140.65): 56 data bytes
		64 bytes from 10.200.140.65: seq=0 ttl=63 time=0.107 ms
		64 bytes from 10.200.140.65: seq=1 ttl=63 time=0.077 ms
		^C
		--- 10.200.140.65 ping statistics ---
		2 packets transmitted, 2 packets received, 0% packet loss
		round-trip min/avg/max = 0.077/0.092/0.107 ms
		/ # ping 223.6.6.6
		PING 223.6.6.6 (223.6.6.6): 56 data bytes
		64 bytes from 223.6.6.6: seq=0 ttl=114 time=19.583 ms
		64 bytes from 223.6.6.6: seq=1 ttl=114 time=28.523 ms
		64 bytes from 223.6.6.6: seq=2 ttl=114 time=21.543 ms
		^C
		--- 223.6.6.6 ping statistics ---
		```
		
		此时ping域名是不通的,因为还没有配dns
		
		```
		/ # cat /etc/resolv.conf 
		nameserver 10.100.0.2
		search default.svc.mycluster.local svc.mycluster.local mycluster.local
		options ndots:5
		```
		
		`10.100.0.2`是K8S内置的DNS
		
	- step4.16 安装coredns
	
		[源码下载](https://dl.k8s.io/v1.21.4/kubernetes.tar.gz)
		
		[客户端下载](https://dl.k8s.io/v1.21.4/kubernetes-client-linux-amd64.tar.gz)
		
		[服务端下载](https://dl.k8s.io/v1.21.4/kubernetes-server-linux-amd64.tar.gz)
		
		[node节点下载](https://dl.k8s.io/v1.21.4/kubernetes-node-linux-amd64.tar.gz)
	
		- 下载后上传至`k8s-master-1`节点的`/usr/local/src/`目录下并解压

		```
		root@k8s-master-1:/etc/kubeasz# cd /usr/local/src/
		root@k8s-master-1:/usr/local/src# ll
		total 462540
		drwxr-xr-x  2 root root      4096 Apr 12 00:50 ./
		drwxr-xr-x 10 root root      4096 Feb 28 17:01 ../
		-rw-r--r--  1 root root  29154332 Apr 12 00:50 kubernetes-client-linux-amd64.tar.gz
		-rw-r--r--  1 root root 118151109 Apr 12 00:50 kubernetes-node-linux-amd64.tar.gz
		-rw-r--r--  1 root root 325784034 Apr 12 00:54 kubernetes-server-linux-amd64.tar.gz
		-rw-r--r--  1 root root    525314 Apr 12 00:47 kubernetes.tar.gz
		root@k8s-master-1:/usr/local/src# tar xf kubernetes-client-linux-amd64.tar.gz
		root@k8s-master-1:/usr/local/src# tar xf kubernetes-node-linux-amd64.tar.gz
		root@k8s-master-1:/usr/local/src# tar xf kubernetes-server-linux-amd64.tar.gz
		root@k8s-master-1:/usr/local/src# tar xf kubernetes.tar.gz
		root@k8s-master-1:/usr/local/src# ll
		total 462544
		drwxr-xr-x  3 root root      4096 Apr 12 00:54 ./
		drwxr-xr-x 10 root root      4096 Feb 28 17:01 ../
		drwxr-xr-x 10 root root      4096 Aug 12  2021 kubernetes/
		-rw-r--r--  1 root root  29154332 Apr 12 00:50 kubernetes-client-linux-amd64.tar.gz
		-rw-r--r--  1 root root 118151109 Apr 12 00:50 kubernetes-node-linux-amd64.tar.gz
		-rw-r--r--  1 root root 325784034 Apr 12 00:54 kubernetes-server-linux-amd64.tar.gz
		-rw-r--r--  1 root root    525314 Apr 12 00:47 kubernetes.tar.gz
		```

		- 各种插件的yaml文件位置
		
		```
		root@k8s-master-1:/usr/local/src/kubernetes# ls cluster/addons/
		addon-manager             cluster-loadbalancing  device-plugins  dns-horizontal-autoscaler  fluentd-gcp    kube-proxy      metadata-proxy  node-problem-detector  rbac       storage-class
		calico-policy-controller  dashboard              dns             fluentd-elasticsearch      ip-masq-agent  metadata-agent  metrics-server  OWNERS                 README.md  volumesnapshots
		```

		- 复制coredns的yaml文件至`/root`
		
		```
		root@k8s-master-1:/usr/local/src/kubernetes/cluster/addons/dns# cd coredns/
		root@k8s-master-1:/usr/local/src/kubernetes/cluster/addons/dns/coredns# ls
		coredns.yaml.base  coredns.yaml.in  coredns.yaml.sed  Makefile  transforms2salt.sed  transforms2sed.sed
		root@k8s-master-1:/usr/local/src/kubernetes/cluster/addons/dns/coredns# cp coredns.yaml.base /root/
		root@k8s-master-1:/etc/kubeasz# cd ~
		root@k8s-master-1:~# mv coredns.yaml.base coredns-k8s-my-cluster.yaml
		```

		- 由于coredns的镜像放在[某个不能说的地方](https://k8s.gcr.io/),故需要[从阿里下载镜像](https://www.cnblogs.com/yinzhengjie/p/12258215.html)并推送至harbor仓库
		
		```
		root@k8s-harbor-2:~# docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.3
		v1.8.3: Pulling from google_containers/coredns
		c6568d217a00: Pull complete 
		a9b089d7de15: Pull complete 
		Digest: sha256:642ff9910da6ea9a8624b0234eef52af9ca75ecbec474c5507cb096bdfbae4e5
		Status: Downloaded newer image for registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.3
		registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.3
		root@k8s-harbor-2:~# docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.3 harbor.k8s.com/baseimages/coredns:v1.8.3
		root@k8s-harbor-2:~# docker push harbor.k8s.com/baseimages/coredns:v1.8.3
		The push refers to repository [harbor.k8s.com/baseimages/coredns]
		85c53e1bd74e: Pushed 
		225df95e717c: Pushed 
		v1.8.3: digest: sha256:db4f1c57978d7372b50f416d1058beb60cebff9a0d5b8bee02bfe70302e1cb2f size: 739
		```

		- 修改yaml文件
		
		```
		root@k8s-master-1:~# vim coredns-k8s-my-cluster.yaml 
		root@k8s-master-1:~# cat coredns-k8s-my-cluster.yaml
		apiVersion: v1
		kind: ServiceAccount
		metadata:
		  name: coredns
		  namespace: kube-system
		---
		apiVersion: rbac.authorization.k8s.io/v1
		kind: ClusterRole
		metadata:
		  labels:
		    kubernetes.io/bootstrapping: rbac-defaults
		  name: system:coredns
		rules:
		  - apiGroups:
		    - ""
		    resources:
		    - endpoints
		    - services
		    - pods
		    - namespaces
		    verbs:
		    - list
		    - watch
		  - apiGroups:
		    - discovery.k8s.io
		    resources:
		    - endpointslices
		    verbs:
		    - list
		    - watch
		---
		apiVersion: rbac.authorization.k8s.io/v1
		kind: ClusterRoleBinding
		metadata:
		  annotations:
		    rbac.authorization.kubernetes.io/autoupdate: "true"
		  labels:
		    kubernetes.io/bootstrapping: rbac-defaults
		  name: system:coredns
		roleRef:
		  apiGroup: rbac.authorization.k8s.io
		  kind: ClusterRole
		  name: system:coredns
		subjects:
		- kind: ServiceAccount
		  name: coredns
		  namespace: kube-system
		---
		apiVersion: v1
		kind: ConfigMap
		metadata:
		  name: coredns
		  namespace: kube-system
		data:
		  Corefile: |
		    .:53 {
		        errors
		        health {
		          lameduck 5s
		        }
		        bind 0.0.0.0
		        ready
		        kubernetes mycluster.local in-addr.arpa ip6.arpa {
		          fallthrough in-addr.arpa ip6.arpa
		        }
		        prometheus :9153
		        # forward . DNS服务器的IP地址 一般在公司集群中有DNS服务器时使用
		        forward . /etc/resolv.conf {
		          max_concurrent 1000
		        }
		        cache 30
		        loop
		        reload
		        loadbalance
		    }
		---
		apiVersion: apps/v1
		kind: Deployment
		metadata:
		  name: coredns
		  namespace: kube-system
		  labels:
		    k8s-app: kube-dns
		    kubernetes.io/name: "CoreDNS"
		spec:
		  # replicas: not specified here:
		  # 1. Default is 1.
		  # 2. Will be tuned in real time if DNS horizontal auto-scaling is turned on.
		  strategy:
		    type: RollingUpdate
		    rollingUpdate:
		      maxUnavailable: 1
		  selector:
		    matchLabels:
		      k8s-app: kube-dns
		  template:
		    metadata:
		      labels:
		        k8s-app: kube-dns
		    spec:
		      priorityClassName: system-cluster-critical
		      serviceAccountName: coredns
		      tolerations:
		        - key: "CriticalAddonsOnly"
		          operator: "Exists"
		      nodeSelector:
		        kubernetes.io/os: linux
		      affinity:
		         podAntiAffinity:
		           preferredDuringSchedulingIgnoredDuringExecution:
		           - weight: 100
		             podAffinityTerm:
		               labelSelector:
		                 matchExpressions:
		                   - key: k8s-app
		                     operator: In
		                     values: ["kube-dns"]
		               topologyKey: kubernetes.io/hostname
		      containers:
		      - name: coredns
		        image: harbor.k8s.com/baseimages/coredns:v1.8.3
		        imagePullPolicy: IfNotPresent
		        resources:
		          limits:
		            memory: 256Mi
		          requests:
		            cpu: 100m
		            memory: 70Mi
		        args: [ "-conf", "/etc/coredns/Corefile" ]
		        volumeMounts:
		        - name: config-volume
		          mountPath: /etc/coredns
		          readOnly: true
		        ports:
		        - containerPort: 53
		          name: dns
		          protocol: UDP
		        - containerPort: 53
		          name: dns-tcp
		          protocol: TCP
		        - containerPort: 9153
		          name: metrics
		          protocol: TCP
		        securityContext:
		          allowPrivilegeEscalation: false
		          capabilities:
		            add:
		            - NET_BIND_SERVICE
		            drop:
		            - all
		          readOnlyRootFilesystem: true
		        livenessProbe:
		          httpGet:
		            path: /health
		            port: 8080
		            scheme: HTTP
		          initialDelaySeconds: 60
		          timeoutSeconds: 5
		          successThreshold: 1
		          failureThreshold: 5
		        readinessProbe:
		          httpGet:
		            path: /ready
		            port: 8181
		            scheme: HTTP
		      dnsPolicy: Default
		      volumes:
		        - name: config-volume
		          configMap:
		            name: coredns
		            items:
		            - key: Corefile
		              path: Corefile
		---
		apiVersion: v1
		kind: Service
		metadata:
		  name: kube-dns
		  namespace: kube-system
		  annotations:
		    prometheus.io/port: "9153"
		    prometheus.io/scrape: "true"
		  labels:
		    k8s-app: kube-dns
		    kubernetes.io/cluster-service: "true"
		    kubernetes.io/name: "CoreDNS"
		spec:
		  type: NodePort
		  selector:
		    k8s-app: kube-dns
		  clusterIP: 10.100.0.2
		  ports:
		  - name: dns
		    port: 53
		    protocol: UDP
		  - name: dns-tcp
		    port: 53
		    protocol: TCP
		  - name: metrics
		    port: 9153
		    protocol: TCP
		    targetPort: 9153
		    nodePort: 30009
		```
		
		具体修改处如下(此处根据原文件修改是无法让coredns启动起来的,因为yaml文件针对的是coredns:v1.8.0,但镜像是coredns:v1.8.3的.故以下修改记录的是修改后的文件行号:
		
		1. 63行:`__DNS__DOMAIN__`:修改为配置集群时的域名,即`/etc/kubeasz/clusters/k8s-my-cluster/hosts`中的`CLUSTER_DNS_DOMAIN`(mycluster.local)
		
		2. 77行:`forward .`:可以修改为阿里的DNS服务器地址(223.6.6.6)
		
		3. 125行:`__DNS__MEMORY__LIMIT__`:可使用的内存最大数量
		
		4. 121行:coredns的镜像地址修改为harbor的地址
		
		5. 191行:`__DNS__SERVER__`修改为容器的IP.即`/etc/kubeasz/clusters/k8s-my-cluster/hosts`中的`SERVICE_CIDR`,将最后一位改为2.在本例中即为将`10.100.0.0/16`修改为`10.100.0.2`
		
		6. 187-203行:
		
		```yaml
		spec:
		  type: NodePort
		  selector:
		    k8s-app: kube-dns
		  clusterIP: 10.100.0.2
		  ports:
		  - name: dns 
		    port: 53
		    protocol: UDP 
		  - name: dns-tcp
		    port: 53
		    protocol: TCP 
		  - name: metrics
		    port: 9153
		    protocol: TCP 
		    targetPort: 9153
		    nodePort: 30009
	```

		- 创建pod并查看
		
		```
		root@k8s-master-1:~# kubectl apply -f coredns-k8s-my-cluster.yaml 
		serviceaccount/coredns created
		clusterrole.rbac.authorization.k8s.io/system:coredns created
		clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
		configmap/coredns created
		deployment.apps/coredns created
		service/kube-dns created
		root@k8s-master-1:~# kubectl get pod -A
		NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
		default       net-test1                                  1/1     Running   0          8h
		default       net-test2                                  1/1     Running   0          8h
		default       net-test3                                  1/1     Running   0          8h
		kube-system   calico-kube-controllers-75b57c64c6-m2ngh   1/1     Running   0          8h
		kube-system   calico-node-5spkh                          1/1     Running   0          8h
		kube-system   calico-node-6pkcz                          1/1     Running   0          8h
		kube-system   calico-node-k6rsg                          1/1     Running   0          8h
		kube-system   calico-node-msd56                          1/1     Running   0          8h
		kube-system   coredns-5b86cf85-nq4zx                     1/1     Running   0          8s
		```

		- 进入容器ping一个域名,检测dns是否生效
		
		```
		root@k8s-node-2:~# kubectl exec -it net-test2 sh
		kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
		/ # ping www.baidu.com
		PING www.baidu.com (39.156.66.18): 56 data bytes
		64 bytes from 39.156.66.18: seq=0 ttl=51 time=10.737 ms
		64 bytes from 39.156.66.18: seq=1 ttl=51 time=10.840 ms
		^C
		--- www.baidu.com ping statistics ---
		2 packets transmitted, 2 packets received, 0% packet loss
		```

		![普罗米修斯的mertics数据](./img/普罗米修斯的mertics数据.png)
		
	- step4.17 安装dashboard
	
		安装dashboard时要注意版本.不是所有的dashboard都兼容所有版本的k8s.此处安装的是dashboard:v2.3.1

		- 下载镜像并推送至harbor
		
		```
		root@k8s-harbor-2:~# docker pull kubernetesui/dashboard:v2.3.1
		v2.3.1: Pulling from kubernetesui/dashboard
		b82bd84ec244: Pull complete 
		21c9e94e8195: Pull complete 
		Digest: sha256:ec27f462cf1946220f5a9ace416a84a57c18f98c777876a8054405d1428cc92e
		Status: Downloaded newer image for kubernetesui/dashboard:v2.3.1
		docker.io/kubernetesui/dashboard:v2.3.1
		root@k8s-harbor-2:~# docker pull kubernetesui/metrics-scraper:v1.0.6
		v1.0.6: Pulling from kubernetesui/metrics-scraper
		47a33a630fb7: Pull complete 
		62498b3018cb: Pull complete 
		Digest: sha256:1f977343873ed0e2efd4916a6b2f3075f310ff6fe42ee098f54fc58aa7a28ab7
		Status: Downloaded newer image for kubernetesui/metrics-scraper:v1.0.6
		docker.io/kubernetesui/metrics-scraper:v1.0.6
		root@k8s-harbor-2:~# docker tag kubernetesui/dashboard:v2.3.1 harbor.k8s.com/baseimages/dashboard:v2.3.1
		root@k8s-harbor-2:~# docker tag kubernetesui/metrics-scraper:v1.0.6 harbor.k8s.com/baseimages/metrics-scraper:v1.0.6
		root@k8s-harbor-2:~# docker push harbor.k8s.com/baseimages/dashboard:v2.3.1
		The push refers to repository [harbor.k8s.com/baseimages/dashboard]
		c94f86b1c637: Pushed 
		8ca79a390046: Pushed 
		v2.3.1: digest: sha256:e5848489963be532ec39d454ce509f2300ed8d3470bdfb8419be5d3a982bb09a size: 736
		root@k8s-harbor-2:~# docker push harbor.k8s.com/baseimages/metrics-scraper:v1.0.6
		The push refers to repository [harbor.k8s.com/baseimages/metrics-scraper]
		a652c34ae13a: Pushed 
		6de384dd3099: Pushed 
		v1.0.6: digest: sha256:c09adb7f46e1a9b5b0bde058713c5cb47e9e7f647d38a37027cd94ef558f0612 size: 736
		```

		- 编辑yaml文件
		
		[yaml文件官方示例](https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml).将内容复制到主机上即可.
		
		```
		root@k8s-master-1:~# vim dashboard-v2.3.1.yaml
		```
		
		1. 修改镜像地址
		2. 39-44行如下:
		
		```yaml
		 39 spec:
		 40   type: NodePort
		 41   ports:
		 42     - port: 443
		 43       targetPort: 8443
		 44       nodePort: 30002
		```

		- 创建pod并查看
		
		```
		root@k8s-master-1:~# kubectl apply -f dashboard-v2.3.1.yaml 
		namespace/kubernetes-dashboard created
		serviceaccount/kubernetes-dashboard created
		service/kubernetes-dashboard created
		secret/kubernetes-dashboard-certs created
		secret/kubernetes-dashboard-csrf created
		secret/kubernetes-dashboard-key-holder created
		configmap/kubernetes-dashboard-settings created
		role.rbac.authorization.k8s.io/kubernetes-dashboard created
		clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
		rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
		clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
		deployment.apps/kubernetes-dashboard created
		service/dashboard-metrics-scraper created
		deployment.apps/dashboard-metrics-scraper created
		root@k8s-master-1:~# kubectl get pod -A
		NAMESPACE              NAME                                        READY   STATUS    RESTARTS   AGE
		default                net-test1                                   1/1     Running   0          8h
		default                net-test2                                   1/1     Running   0          8h
		default                net-test3                                   1/1     Running   0          8h
		kube-system            calico-kube-controllers-75b57c64c6-m2ngh    1/1     Running   0          8h
		kube-system            calico-node-5spkh                           1/1     Running   0          8h
		kube-system            calico-node-6pkcz                           1/1     Running   0          8h
		kube-system            calico-node-k6rsg                           1/1     Running   0          8h
		kube-system            calico-node-msd56                           1/1     Running   0          8h
		kube-system            coredns-5b86cf85-nq4zx                      1/1     Running   0          28m
		kubernetes-dashboard   dashboard-metrics-scraper-69995b67c-vswhv   1/1     Running   0          22s
		kubernetes-dashboard   kubernetes-dashboard-54d6cc67d5-ckwj9       1/1     Running   0          22s
		```
		
![k8s-dashboard](./img/k8s-dashboard.png)
		
		注意:必须以https协议访问.且此时需要token

		- 编辑用户角色配置yaml文件并执行
		
		```
		root@k8s-master-1:~# vim admin-user.yml
		root@k8s-master-1:~# cat admin-user.yml
		apiVersion: v1
		kind: ServiceAccount
		metadata:
		  name: admin-user
		  namespace: kubernetes-dashboard
		
		---
		apiVersion: rbac.authorization.k8s.io/v1
		kind: ClusterRoleBinding
		metadata:
		  name: admin-user
		roleRef:
		  apiGroup: rbac.authorization.k8s.io
		  kind: ClusterRole
		  name: cluster-admin
		subjects:
		- kind: ServiceAccount
		  name: admin-user
		  namespace: kubernetes-dashboard
		```

		- 查看密钥
		
		```
		root@k8s-master-1:~# kubectl get secrets -A|grep admin
		kubernetes-dashboard   admin-user-token-ckjbb                           kubernetes.io/service-account-token   3      29s
		root@k8s-master-1:~# kubectl describe secrets admin-user-token-ckjbb -n kubernetes-dashboard
		Name:         admin-user-token-ckjbb
		Namespace:    kubernetes-dashboard
		Labels:       <none>
		Annotations:  kubernetes.io/service-account.name: admin-user
		              kubernetes.io/service-account.uid: 87a2cf36-54d5-4859-b969-15a1737e7b27
		
		Type:  kubernetes.io/service-account-token
		
		Data
		====
		token:      eyJhbGciOiJSUzI1NiIsImtpZCI6ImUzT3IyWkJaRFVWQS13VTdUR3hXY2d3dEZpd1VSVDQtb3ZXdkNCMnkzOFEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLWNramJiIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI4N2EyY2YzNi01NGQ1LTQ4NTktYjk2OS0xNWExNzM3ZTdiMjciLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.ZFh31-Zae4dl4x56kJpGm7bqVrofH4H9rFiXlOqxyZAQf66BPAJL0hI86EtSyCaB7OwbeYFySLQfsnShtJdBbB2cmynR8fmvqI0VGw2vYVY1WgVq1ARPoCZndgSHXgZnk1y4eStZIN0qPeThbKgFdowOAtWqqXuH1OxC1heVrWpeGG6tQIGwZwdPFAD6-jV3KxVzCDxfyAoSmcHQAnQiyjYACoK-e4icbClCdzsEevNSBflIDV4cSahVSA9lNoP-t6IuONBttwcrh-ya2MPjG4CEJXmVYK-o6LNjr_Lt4t4ZWHdjP-l9NvDuOpd1Zkbwc66o6HTGtnLC2h7njTe8HA
		ca.crt:     1350 bytes
		namespace:  20 bytes
		```
		
![k8s-dashboard-登录后](./img/k8s-dashboard-登录后.png)