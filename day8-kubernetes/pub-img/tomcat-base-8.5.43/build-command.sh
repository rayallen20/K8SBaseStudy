#!/bin/bash
docker build -t harbor.k8s.com/pub-images/tomcat-base:v8.5.43 .
sleep 3
docker push harbor.k8s.com/pub-images/tomcat-base:v8.5.43