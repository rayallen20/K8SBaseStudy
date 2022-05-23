FROM harbor.k8s.com/pub-images/jdk-base:v8.212 

MAINTAINER Roach 40486453@qq.com

RUN yum install file -y
RUN mkdir -p /apps/dubbo/consumer 
ADD dubbo-demo-consumer-2.1.5  /apps/dubbo/consumer
ADD run_java.sh /apps/dubbo/consumer/bin 
RUN chown nginx.nginx /apps -R
RUN chmod a+x /apps/dubbo/consumer/bin/*.sh

CMD ["/apps/dubbo/consumer/bin/run_java.sh"]