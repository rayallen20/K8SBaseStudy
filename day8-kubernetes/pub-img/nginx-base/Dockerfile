FROM harbor.k8s.com/baseimages/erp-centos-base:7.8.2003
MAINTAINER Roach 40486453@qq.com
ADD nginx-1.18.0.tar.gz /usr/local/src/
RUN yum install -y vim wget tree  lrzsz gcc gcc-c++ automake pcre pcre-devel zlib zlib-devel openssl openssl-devel iproute net-tools iotop
RUN cd /usr/local/src/nginx-1.18.0 && ./configure  && make && make install && ln -sv  /usr/local/nginx/sbin/nginx /usr/sbin/nginx  &&rm -rf /usr/local/src/nginx-1.18.0.tar.gz 