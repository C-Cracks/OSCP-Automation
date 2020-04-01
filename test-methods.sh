#!/usr/bin/bash

methods=("TRACE" "GET" "PUT" "HEAD" "DELETE" "CONNECT" "OPTIONS" "invalid")

echo -e "$( tput bold )C-Cracks\nHTTP Methods Testing$( tput sgr0 )"

for m in "${methods[@]}";do
	if [[ $( echo "$1" | grep https ) ]] ; then
		if [[ $( echo "$m" | grep "HEAD" ) ]]; then figlet "${m} Request" && curl --insecure --head "$1"
		else figlet "${m} Request" && curl --insecure -X "${m}" "$1" ; fi
	elif [[ $( echo "$1" | grep http ) ]] ; then
		if [[ $( echo "$m" | grep "HEAD" ) ]]; then figlet "${m} Request" && curl --head "$1"
		else figlet "${m} Request" && curl -X "${m}" "$1" ; fi
	fi
done
exit 0
