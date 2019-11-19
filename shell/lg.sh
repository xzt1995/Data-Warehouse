#!/bin/bash
for i in hadoop102 hadoop103
	do
	 ssh $i  "java -classpath /opt/module/log-collector-1.0-SNAPSHOT-jar-with-dependencies.jar com.xzt.appclient.AppMain $1 $2 >/opt/module/test.log &"
	done
