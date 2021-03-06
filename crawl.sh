#!/bin/bash
# AUTHOR: Joey Stevens
# DESCRIPTION: A multithreaded web crawler

source crawler.conf.sh
trap dontExit EXIT
trap killme INT 

function killme() {
	pgrep -f "$0" | parallel pgrep -P {} | parallel kill -9 {} # Kill child procs
	pgrep -f "$0" | parallel kill -9 {} # Kill parent procs
}

function reallyDontExit() {
	# If we hit more than one deadend
	dontExit
}

function dontExit { 
	source crawler.conf.sh
	echo "It appears we've hit a deadend.. Crawling somewhere new"
	url=$(shuf -n1 $sitelist)
	echo "Crawling $url"
	resp=$(curl -s $url)
	crawlLinks "$resp" "$url"
	reallyDontExit
}

function doNothing() {
	echo -n
}


function removeWhiteSpace() {
	# Why is this needed? Especially the massive trailing \s ???
	echo -e "$1" | tr -d "[[:space:]]" | sed 's/\\//g'
}

function multithreaded () {
	# Takes data from /dev/stdin
	# Executes arg
	# Examples seq 1 10 | multithreaded echo {}
	source crawler.conf.sh 
	command_to_execute="$1"
	if [ -n "$cthreads" ]; then threads=$cthreads; fi
	parallel --no-notice --no-run-if-empty -j $threads "$command_to_execute";
}

function escapeUrl() {
	# expects url and returns escaped url
	echo "$1" | sed 's/\//\\\//g' 
				# s/ \/ / \\\/ /g
				# s/ escaped / replace escaped \ escaped / 
}

function getDateTime() {
	date +"%Y-%m-%d %T.%6N"
}

function executeQuery() {
	source crawler.conf.sh 
	query="$1"
	mysql --defaults-extra-file="$mysqlAuthFile" --execute="$query"
}

function overwriteTmpFile() {
	source crawler.conf.sh
	echo -e "$1" > $tmpfile
}

function log() {
	datetime=$(getDateTime)
	link="$1"
	locationDiscovered="$2"
	domain="$3"
	SQL="insert into links values(id, \"$link\", \"$locationDiscovered\", \"$domain\", \"$datetime\");"
	executeQuery "$SQL"
}

function getLinks() {
	## expects curl response as $1 and the request url as $2
	## returns links
	resp="$1"
	url="$2"
	escaped_url=$(escapeUrl "$url")
	protocol=$(echo "$url" | grep -ioP "htt(ps|p)")
	links=$(echo -e "$resp" | pup 'a, src, img, link attr{href}')

	links_that_build_on_domain=$(echo -e "$links" | grep -iE "^/([a-z]|[0-9])") # /stuff/things.html
	protocol_relative_links=$(echo -e "$links" | grep -iE "^//([a-z]|[0-9])") # //link.com

	rebuilt_links_that_build_on_domain=$(echo -e "$links_that_build_on_domain" | sed "s/^/$escaped_url/g")
	rebuilt_protocol_relative_links=$(echo -e "$protocol_relative_links" | sed "s/^\/\//$protocol:\/\//g" ) # replace // with $protocl://
	already_built_links=$(echo -e "$links" | grep -iE "htt(p|ps)://") # https://stuff.com

	linklist=$(echo -e "$rebuilt_links_that_build_on_domain\n$rebuilt_protocol_relative_links\n$already_built_links")
	linklist=$(echo -e "$linklist" | awk '!a[$0]++' ) # Removes duplicates from the list 
	echo -e "$linklist"
}

function checkForDupes() {
	# Returns nothing if duplicate
	link="$1"
	url="$2"
	domain="$3"
	datetime=$(getDateTime)
	overwriteTmpFile "$link\n$url\n$domain\n$datetime"
	url_cleaned=$(echo "$url" | cut -d"/" -f3- | tr -d "/") # Remove protocol and slashes
	link_cleaned=$(echo "$link" | cut -d"/" -f3- | tr -d "/") # Makes sure that https://github.com matches github.com or http://github.com or https://github.com/
	if [[ "$url_cleaned" != "$link_cleaned" ]]; then  # If the link we're checking does not equal the URL we started crawlings
		linksOnThatDomain=$(executeQuery "SELECT link FROM links WHERE domain=\"$domain\";")
		if [ -n "$linksOnThatDomain" ]; then  # If there are some links on that domain
			for link in $(echo -e "$linksOnThatDomain"); do # Iterate through the links
				if [[ "$link" == "$link" ]]; then # If the link we're checking equals that link
					doNothing # This means failure
				else 
					exactMatch=$(executeQuery "SELECT id FROM links WHERE link=\"$link\" AND locationDiscovered=\"$url\" AND domain=\"$domain\"")
					if [ -z "$exactMatch" ]; then  # If there was no match 
						echo "Not a duplicate" # Success
					fi
				fi
			done
		else # If there are no links on that domain then do an exact match check
				exactMatch=$(executeQuery "SELECT id FROM links WHERE link=\"$link\" AND locationDiscovered=\"$url\" AND domain=\"$domain\"")
			if [ -z "$exactMatch" ]; then  # If there was no match 
				echo "Not a duplicate" # Success
			fi
		fi
	fi
}

ifNoDupesThenLog() {
	link="$1"
	url="$2"
	domain="$3"
	link=$(removeWhiteSpace "$link")
	url=$(removeWhiteSpace "$url")
	domain=$(removeWhiteSpace "$domain")

	if [ "$(checkForDupes "$link" "$url" "$domain")" ]; then 
		echo $link
		log "$link" "$url" "$domain"
	else
		echo "Already have that logged"
	fi
}

function goDeeper() {
	url="$1"
	resp=$(curl -s "$url")
	crawlLinks "$resp" "$url"
}

function crawlLinks() {
	## Expects curl response as $1 and request url as $2
	## crawls links, logs links, crawls more links
	resp="$1"
	url="$2"
	domain=$(echo "$url" | cut -d"/" -f3)
	linklist=$(getLinks "$resp" "$url") 
	echo -e "$linklist" | multithreaded "ifNoDupesThenLog \"{}\" \"$url\" \"$domain\""
	for i in $(echo -e "$linklist"); do
		if [[ "$i" != "$url" ]]; then 
			goDeeper "$i" # Where are these \s and ?s coming from??
		fi
	done
}


source argparse.sh
source exports.sh

argParse "$@"
