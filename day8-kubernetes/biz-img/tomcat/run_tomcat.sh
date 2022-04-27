#!/bin/bash
# 此处必须以和nginx容器中启动nginx的用户相同的用户启动tomcat
# 否则nginx转发给时会报403错误 该用户在构建centos基础镜像时就已经创建了
su - nginx -c "/apps/tomcat/bin/catalina.sh start"
tail -f /etc/hosts