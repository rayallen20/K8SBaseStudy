#!/bin/bash
docker build -t harbor.k8s.com/baseimages/erp-centos-base:7.8.2003 . --network=host
docker push harbor.k8s.com/baseimages/erp-centos-base:7.8.2003
