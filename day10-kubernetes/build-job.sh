#!/bin/bash
# Author: Roach
# Date: 2022-06-02
# Version: v1

# 记录脚本开始执行的时间
startTime=`date +'%Y-%m-%d %H:%M:%S'`

# 脚本存放的路径
SHELL_DIR="/root/scripts"

# 脚本名称
SHELL_NAME="$0"

# K8S集群的master节点IP
K8S_CONTROLLER="172.16.1.181"

# 制作镜像的服务器节点IP
IMAGE_BUILDER="172.16.1.185"

# 获取当前日期 精确到秒 用于构建镜像时的版本号
DATE=`date +%Y-%m-%d_%H_%M_%S`

# 定义执行脚本时的操作 操作只能为部署或回滚
METHOD=$1

# 若操作为部署 则指定部署哪个分支的代码
Branch=$2

# 若未指定分支 则分支为dev
if test -z $Branch;then
	Branch=dev
fi

# 本函数用于克隆代码
function Code_Clone(){
	# 项目的git地址
	Git_URL="git@192.168.0.194:erp/user.git"

	# 取项目名
	DIR_NAME=`echo ${Git_URL} | awk -F "/" '{print $2}' | awk -F "." '{print $1}'`

	# 定义代码存放目录
	DATA_DIR="/data/gitdata/erp"
	Git_dir="${DATA_DIR}/${DIR_NAME}"

	# 拉取代码 此处拉取的方式为删除已存在的代码 然后重新克隆
	# 删除已存在的代码
	cd ${DATA_DIR} && echo "delete previous version of code and clone the latest version of code with current branch" && sleep 1 && rm -rf ${DIR_NAME}

	# 克隆代码
	echo "clone from branch:${Branch} will be start soon" && sleep 1
	git clone -b ${Branch} ${Git_URL}

	# 编译代码
	# 此处要看具体是什么语言的代码
	# java代码如下:
	# cd ${Git_dir} && mvn clean package
	# go代码如下:
	# go build xxx(二进制文件名)

	# 将代码打成压缩包
	sleep 1
	cd ${Git_dir}
	tar zcf app.tar.gz ./*
}

# 本函数用于将打包好的压缩文件拷贝到制作镜像的服务器
function Copy_file(){
	echo "compress code into package finish.Copy to image builder node:${IMAGE_BUILDER} will be start soon" && sleep 1
	scp app.tar.gz root@${IMAGE_BUILDER}:/opt/k8s-data/biz-img/tomcatapp
	echo "copy package finish.node:${IMAGE_BUILDER} build image will be start soon" && sleep 1
}

# 本函数用于到制作镜像的服务器上制作镜像并上传至harbor
function Make_Image(){
	echo "build image and push to harbor start" && sleep 1
	# 以制作镜像的日期(精确到秒)作为镜像的版本号 构建并推送镜像至harbor
	ssh root@${IMAGE_BUILDER} "cd /opt/k8s-data/biz-img/tomcatapp && bash build-command.sh ${DATE}"
	echo "build image and push to harbor finish" && sleep 1
}

# 本函数用于到K8S的master节点上更新yaml文件中的镜像版本号 
# 从而保持yaml文件中的镜像版本号与K8S中的版本号一致
function Update_k8s_yaml(){
	echo "update image which exist in yaml will be start soon" && sleep 1
	ssh root@${K8S_CONTROLLER} "cd /root/k8s-data/tomcat-webapp-yaml && sed -i 's/image: harbor.k8s.*/image: harbor.k8s.com\/erp\/tomcat-webapp:${DATE}/g' tomcat-webapp-deployment.yaml"
	echo "update image which exist in yaml finish.Update container will be start soon" && sleep 1
}

# 本函数用于更新K8S中容器的版本 通过使用kubectl set image的方式更新 不推荐使用此方式
function Update_k8s_container_by_set_image(){
	ssh root@${K8S_CONTROLLER} "kubectl set image deployment/erp-tomcat-webapp-deployment erp-tomcat-webapp-container=harbor.k8s.com/erp/tomcat-webapp:${DATE} -n erp"
}

# 本函数用于更新K8S中容器的版本 通过kubectl apply -f的方式更新 推荐使用此方式
function Update_k8s_container_by_apply_yaml(){
	ssh root@${K8S_CONTROLLER} "cd /root/k8s-data/tomcat-webapp-yaml && kubectl apply -f tomcat-webapp-deployment.yaml --record"
	echo "update image which exist in k8s finish" && sleep 1
	echo "now image version is:harbor.k8s.com/erp/tomcat-webapp:${DATE}"

	# 计算脚本累计执行时间 若不需要可删除
	endTime=`date +'%Y-%m-%d %H:%M:%S'`
	start_seconds=$(date --date="$startTime" +%s);
	end_seconds=$(date --date="$endTime" +%s);
	echo "update image cost: "$((end_seconds-start_seconds))" seconds"
}

# 本函数用于将K8S中的镜像回滚到上一个版本
function Rollback_last_version(){
	echo "rollback to last version will be start soon"
	ssh root@${K8S_CONTROLLER} "kubectl rollout undo deployment/erp-tomcat-webapp-deployment -n erp"
	sleep 1
	echo "rollback to last version finish"
}

# 本函数用于使用帮助
usage(){
	echo "the way to deploy is: ${SHELL_DIR}/${SHELL_NAME} deploy"
	echo "the way to rollback last version is: ${SHELL_DIR}/${SHELL_NAME} Rollback_last_version"
}

# 主函数
main(){
	case ${METHOD} in
	deploy)
	  Code_Clone;
	  Copy_file;
	  Make_Image;
	  Update_k8s_yaml;
	  Update_k8s_container_by_apply_yaml;
	;;
	rollback_last_version)
	  Rollback_last_version;
	;;
	*)
	  usage;
	esac;
}

main $1 $2
