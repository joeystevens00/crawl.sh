#!/bin/bash

source ../crawler.conf.sh

duplicates=$(mysql --defaults-extra-file=$mysqlAuthFile  < checkForDuplicates.sql)

if [ -z "$duplicates" ]; then
		echo "PASS: duplicate check"
else
		echo "FAIL: duplicate check"
		echo "Duplicates: $duplicates"
fi