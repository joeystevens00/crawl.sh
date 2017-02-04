#!/bin/bash
displayHelp() {
	echo "Placeholder help"
	sleep 1
	less $0
	killme
}

argParse() {
	for i in "$@"; do
	case $i in
		-u=*|--url=*)
			url="${i#*=}"
			shift # past argument=value
             ;;
		-t=*|--threads=*)
    		cthreads="${i#*=}"
    		shift # past argument=value
    		;;
        -h|--help=*)
    		help=true
            shift # past argument=value
        	;;
    	*)
	       	help=true # unknown option
    		;;
	esac
	done

	if [ "$help" == true ]; then displayHelp; fi

	if [ -z "$url" ]; then
		if [ -f "$tmpfile" ]; then 
			lastLinkChecked=$(head -1 $tmpfile)
			url=$lastLinkChecked
		else 
			echo "No URL passed and this appears to be our first run.."
			url=$(shuf -n1 $sitelist)
			echo "Starting with: $url"
		fi
	fi
	resp=$(curl -s $url)
	crawlLinks "$resp" "$url" 
}