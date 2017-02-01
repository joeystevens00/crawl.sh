#!/bin/bash
source crawler.conf.sh

checkIfInstalled.sh parallel
checkIfInstalled.sh mysql
checkIfInstalled.sh curl

if [ ! -f $mysqlAuthFile ]; then 
	echo "Mysql auth config file not found"
	echo "Creating at: $mysqlAuthFile"
	echo -e "[client]\nuser=\"\"\npassword=\"\"\nhost=\"\"\ndatabase=\"\"" > $mysqlAuthFile
fi

parallelVersion=$(parallel --version)
if [[ "$parallelVersion" != *"GNU"* ]]; then 
	echo "It appears that the version of parallel you have
	is not GNU parallel (perhaps moreutils?). Install the latest
	version of GNU parallel"
fi
