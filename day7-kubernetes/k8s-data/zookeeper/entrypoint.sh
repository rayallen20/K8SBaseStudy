#!/bin/bash

# 生成serverID并打印 MYID是创建pod时写入的环境变量
echo ${MYID:-1} > /zookeeper/data/myid

# SERVERS是创建pod时写入的环境变量
if [ -n "$SERVERS" ]; then
	IFS=\, read -a servers <<<"$SERVERS"
	for i in "${!servers[@]}"; do 
		# 将serverID追加到zk的配置文件中
		printf "\nserver.%i=%s:2888:3888" "$((1 + $i))" "${servers[$i]}" >> /zookeeper/conf/zoo.cfg
	done
fi

cd /zookeeper
exec "$@"
