#!/bin/bash


cat /tmp/hosts >> /etc/hosts
service mapr-zookeeper start
service mapr-warden start






