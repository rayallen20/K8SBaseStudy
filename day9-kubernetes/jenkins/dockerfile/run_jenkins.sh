#!/bin/bash
cd /apps/jenkins && java -server -Xms1024m -Xmx1024m -Xss512k -jar jenkins-2.190.1.war --webroot=/apps/jenkins/jenkins-data --httpPort=8080