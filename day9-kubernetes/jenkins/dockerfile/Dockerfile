FROM harbor.k8s.com/pub-images/jdk-base:v8.212

MAINTAINER Roach 40486453@qq.com

ADD jenkins-2.190.1.war /apps/jenkins/
ADD run_jenkins.sh /usr/bin/


EXPOSE 8080 

CMD ["/usr/bin/run_jenkins.sh"]