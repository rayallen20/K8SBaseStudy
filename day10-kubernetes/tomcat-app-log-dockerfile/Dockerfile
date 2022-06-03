FROM harbor.k8s.com/pub-images/tomcat-base:v8.5.43
MAINTAINER Roach 40486453@qq.com

ADD catalina.sh /apps/tomcat/bin/catalina.sh
ADD server.xml /apps/tomcat/conf/server.xml
ADD app.tar.gz /data/tomcat/webapps/myapp/
ADD run_tomcat.sh /apps/tomcat/bin/run_tomcat.sh

# 此处需将tomcat的安装路径和业务代码的存放路径的属主属组修改为和nginx容器中运行
# nginx的用户相同的用户
RUN chown -R nginx.nginx /data/ /apps/

# 安装filebeat
# ADD filebeat-7.6.2-x86_64.rpm /tmp
# RUN yum install -y /tmp/filebeat-7.6.2-x86_64.rpm
ADD filebeat.yml /etc/filebeat/filebeat.yml 

EXPOSE 8080 8443

CMD ["/apps/tomcat/bin/run_tomcat.sh"]