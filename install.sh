#!/bin/bash
source crawler.conf.sh

shopt -s nocasematch


function checkIfInstalled() {
	command -v $1 >/dev/null 2>&1 || { echo "false"; }
}

function setupGo() {
	apt-get install golang
	godir=$1
	mkdir "$godir"
	export GOPATH=$godir
	echo "export GOPATH=$godir" >> ~/.bashrc
	go get https://github.com/ericchiang/pup
	cp $godir/bin/pup /usr/bin
}

if [[ `whoami` != 'root' ]]; then 
	echo "Run me as root"
	exit 1
elif [ `checkIfInstalled parallel` ] || [ `checkIfInstalled mysql` ] ||
	[ `checkIfInstalled curl` ] || [ `checkIfInstalled pgrep` ]; then
	apt-get update 
	apt-get install mysql-client curl parallel procps
elif [ `checkIfInstalled pup` ]; then
	timestamp=`date "+%s"`
	godir="~/.go"
	godirtime="$godir-$timestamp"
	if [ ! -d "$godir" ]; then
		setupGo "$godir"
	elif [ ! -d "$godirtime" ]; then
		setupGo "$godirtime"
	else 
		echo "Cannot setup Go at this time"
	fi
elif [ ! -f $mysqlAuthFile ]; then 
	echo "Mysql auth config file not found"
	echo "Creating at: $mysqlAuthFile"
	echo -e "[client]\nuser=\"\"\npassword=\"\"\nhost=\"\"\ndatabase=\"\"" > $mysqlAuthFile
    echo "Edit the file now (will open vi)? [y|n]" 
	while read answer; do
    	case "$answer" in
        	y)
            	vi $mysqlAuthFile
            	echo "Create the required database and table now? [y|n]"
            	while read answer; do
            		case "$answer" in
            			y)
							mysql --defaults-extra-file=$mysqlAuthFile  < crawler.sql
                			break
                			;;
                		n)
							echo "Run crawler.sql before running crawl.sh"
							break
							;;
						*)
							echo 'Select [y|n]'
						esac
				done
				break
				;;
            n)
				echo "Edit the file $mysqlAuthFile and then run crawler.sql"
                break;
                ;;
            *)
            	echo 'Select [y|n]'
    	esac;
	done
fi

parallelVersion=$(parallel --version)
if [[ "$parallelVersion" != *"GNU"* ]]; then 
	echo "It appears that the version of parallel you have
	is not GNU parallel (perhaps moreutils?). Install the latest
	version of GNU parallel"
fi
