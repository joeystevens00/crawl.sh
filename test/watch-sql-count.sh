#!/bin/bash

# Ensure directory sanity
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

source ../crawler.conf.sh

watch "mysql --defaults-extra-file=$mysqlAuthFile --execute='SELECT COUNT(id) FROM links;'"

