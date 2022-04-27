FROM harbor.k8s.com/pub-images/jdk-base:v8.212
MAINTAINER Roach 40486453@qq.com

# /apps 用于tomcat的安装路径
# /data/tomcat/webapps 用于存放代码
# /data/tomcat/logs 用于存放tomcat日志
RUN mkdir -pv /apps /data/tomcat/webapps /data/tomcat/logs
ADD apache-tomcat-8.5.43.tar.gz  /apps
RUN useradd tomcat -u 2022 && ln -sv /apps/apache-tomcat-8.5.43 /apps/tomcat && chown -R tomcat.tomcat /apps /data -R