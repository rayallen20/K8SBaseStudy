#!/bin/bash
TAG=$1
docker build -t  harbor.k8s.com/erp/tomcat-webapp:${TAG} .
sleep 3
docker push  harbor.k8s.com/erp/tomcat-webapp:${TAG}