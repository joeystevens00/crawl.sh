source ../crawler.conf.sh

watch "mysql --defaults-extra-file=$mysqlAuthFile --execute='SELECT COUNT(id) FROM links;'"

