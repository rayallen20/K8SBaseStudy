#!/bin/bash
su - nginx -c "/apps/dubbo/provider/bin/start.sh"
tail -f /etc/hosts