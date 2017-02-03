#!/bin/bash
source crawler.conf.sh

shopt -s nocasematch

checkIfInstalled.sh parallel
checkIfInstalled.sh mysql
checkIfInstalled.sh curl
checkIfInstalled.sh pup
if [ ! -f $mysqlAuthFile ]; then 
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
