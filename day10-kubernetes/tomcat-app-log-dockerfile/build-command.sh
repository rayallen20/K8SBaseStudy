#!/bin/bash
TAG=$1
docker build -t  harbor.k8s.com/erp/tomcat-webapp-log:${TAG} .
sleep 3
docker push  harbor.k8s.com/erp/tomcat-webapp-log:${TAG}