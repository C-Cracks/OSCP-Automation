#!/usr/bin/bash

#Automation of part of the first step of enumeration- information gathering.
#Script performs nmap vulners scan, dirb based on the results of nmap and nikto based on the same
#Also performs a quick check for the existence of anonymous ftp access if relevant
#May add to this as time passes and I learn more

# Just some fancy banner stuff 
figlet "C-Cracks" ; figlet "Initial Enum" ; echo "Services and Web Servers"
ip=$1 && echo -e "Target: ${ip}\nCommencing with nmap scan..."

# perform Nmap scan on all ports using NSE script vulners
# Zenity creates alert boxes- removes the need to keep checking the terminal for output
nmap -oN ./nmap-scan-results.txt -T4 -sC -sV ${ip} -p-  > /dev/null 2>&1 && zenity --info --text="Nmap Scan On ${ip} Complete. Results saved to nmap-scan-results.txt."
cat ./nmap-scan-results.txt 

# collect relevant ports and place into variables for use later
# if more than 1 port returned, append to array, else continue with orig execution
http_p=( `cat ./nmap-scan-results.txt | grep "http" | grep -v "ssl" | grep -v "over" | grep -v "HTTPAPI" | cut -d'/' -f 1 | grep -v [A-Za-z] || echo "HTTP not found."` )
https_p=( `cat ./nmap-scan-results.txt | grep "ssl/http" | cut -d'/' -f 1 | grep -v [A-Za-z] || echo "HTTPS not found."` )

# run enum4linux against target if target is linux
if [[ $( cat nmap-scan-results.txt | grep -E -- "smb|microsoft-ds" ) ]] ; then echo -e "\nRunning enum4linux..." ; enum4linux "${ip}" > linux-enum.txt ; cat linux-enum.txt ; fi

# perform wfuzz scans
if [[ $( echo "${http_p[@]}" | grep -v "not found" ) ]] && [[ $( echo "${https_p[@]}" | grep -v "not found" ) ]] ; then 
	echo "Found HTTP and HTTPS, commencing with wfuzz..."
	for i in "${http_p[@]}"; do
		timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ >> ./http-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.txt >> ./http-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.php >> ./http-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.log >> ./http-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.html >> ./http-wfuzz${i}.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to http-wfuzz${i}.txt" ; sleep 1
	done
	for i in "${https_p[@]}"; do
		timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ >> ./https-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.txt >> ./https-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.php >> ./https-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.log >> ./https-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.html >> ./https-wfuzz${i}.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to https-wfuzz${i}.txt." ; sleep 1
	done
	
elif [[ $( echo "${http_p[@]}" | grep "not found" ) ]]  && [[ $( echo "${https_p[@]}" | grep -v "not found" ) ]] ; then 
	echo "Found HTTPS, commencing with wfuzz..."
	for i in "${https_p[@]}"; do
		timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ >> ./https-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.txt >> ./https-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.php >> ./https-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.log >> ./https-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.html >> ./https-wfuzz${i}.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to https-wfuzz${i}.txt." ; sleep 1
	done
	
elif [[ $( echo "${http_p[@]}" | grep -v "not found" ) ]] && [[ $( echo "${https_p[@]}" | grep "not found" ) ]]; then 
	echo "Found HTTP, commencing with wfuzz..."
	for i in "${http_p[@]}"; do
		timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ >> ./http-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.txt >> ./http-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.php >> ./http-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.log >> ./http-wfuzz${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.html >> ./http-wfuzz${i}.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to http-wfuzz${i}.txt." ; sleep 1
	done
	
else echo "Did not find a web server..." && web_server="false"
fi

if ! [[ -v $web_server ]] ; then
	# curl found results
	if [[ $( echo "${http_p[@]}" | grep -v "not found" ) ]] ; then
		
		for i in "${http_p[@]}"; do
			cat http-wfuzz${i}.txt | grep -v "404" | grep -o '".*"' | tr -d '"' | sort -u > ./http-curl${i}.txt
			if [[ $( cat ./http-curl${i}.txt | wc -l ) -lt 1000 ]] ; then
				while IFS="" read -r p || [ -n "$p" ] ; do
					url=$( echo "$p" | tr -d '\n' )
					echo "HTTP port ${i}" >> ./http-curl.txt ; echo -e "$p\n" >> ./http-curl.txt && curl "http://${ip}:${i}/$url/" >> ./http-curl.txt && echo -e "\n\n" >> ./http-curl.txt
					if echo "$p" | grep -E -- "login|admin|portal|robots" > /dev/null 2>&1 ; then echo -e "\e[33m\e[1m$p\e[0m\e[33m on HTTP port ${i} may be interesting...\e[0m" ; fi
				done < ./http-curl${i}.txt && zenity --info --text="HTTP port ${i} cURL Requests on wfuzz Results Complete. Results saved."
			else echo "1000+ pages found, skipping cURL (check http-wfuzz${i}.txt manually.)"
			fi
		done
	fi

	if [[ $( echo "${https_p[@]}" | grep -v "not found" ) ]] ; then

		for i in "${https_p[@]}"; do
			cat https-wfuzz${i}.txt | grep -v "404" | grep -o '".*"' | tr -d '"' | sort -u > ./https-curl${i}.txt
			if [[ $( cat ./https-curl${i}.txt | wc -l ) -lt 1000 ]] ; then
				while IFS="" read -r p || [ -n "$p" ] ; do
					url=$( echo "$p" | tr -d '\n' )
					echo "HTTPS port ${i}" >> ./https-curl.txt ; echo -e "$p\n" >> ./https-curl.txt && curl --insecure "https://${ip}:${i}/$url/" >> ./https-curl.txt && echo -e "\n\n" >> ./https-curl.txt
					if echo "$p" | grep -E -- "login|admin|portal|robots" > /dev/null 2>&1 ; then echo -e "\e[33m\e[1m$p\e[0m\e[33m on HTTPS port ${i} may be interesting...\e[0m" ; fi
				done < ./https-curl${i}.txt  && zenity --info --text="HTTPS port ${i} cURL Requests on wfuzz Results Complete. Results saved."
			else echo "1000+ pages found, skipping cURL (check https-wfuzz${i}.txt manually.)"
			fi
		done
	
	fi

	# nikto sncans
	echo -e "\nCommencing with Nikto Scans..."
	if [[ $( echo "${http_p[@]}" | grep -v "not found" ) ]]; then
		for i in "${http_p[@]}"; do 
			echo "no" | nikto -h "${ip}:${i}" -nointeractive -maxtime 360 >> nikto-results.txt && zenity --info --text="Nikto HTTP Scan for port ${i} Complete. Results saved to nikto-requests.txt."
		done
	fi
	if [[ $( echo "${https_p[@]}" | grep -v "not found" ) ]] ;then
		for i in "${https_p[@]}"; do
			echo "no" | nikto -h "${ip}:${i}" -nointeractive -maxtime 360 >> nikto-results.txt  && zenity --info --text="Nikto HTTPS Scan for port ${i} Complete. Results saved to nikto-requests.txt."
		done
	fi
fi

cat ./nikto-results.txt 
if cat ./nikto-results.txt | grep -E -- "wordpress|WordPress|Wordpress" > /dev/null 2>&1 ; then echo "WordPress discovered, you should run WPScan." ; fi
echo "Initial enumeration complete" && ls -al 

open_ps=$( cat ./nmap-scan-results.txt | grep "open" )  
echo -e "\e[33m\e[1mRESULTS:\e[0m\e[33m\e[0m"
echo -e "Open Ports:\n${open_ps}" 

if [[ $( echo "${http_p[@]}" | grep -v "not found" ) ]] ; then
	for i in "${http_p[@]}"; do
		if [[ $( cat ./http-curl${i}.txt | wc -l ) -lt 1000 ]] ; then
			resp=$( cat ./http-wfuzz${i}.txt | grep "  200" )
			echo -e "\nHTTP files on port ${i} returning 200 response (see http-wfuzz${i}.txt):\n${resp}\n" && if [[ $( cat ./http-curl${i}.txt | grep -E -- "login|admin|portal|robots" ) ]] ; then echo -e "Interesting Files on HTTP port ${i}:\n$( cat ./http-curl${i}.txt | grep -E -- 'login|admin|portal|robots' )" ; fi 
		fi
	done
fi

if [[ $( echo "${https_p[@]}" | grep -v "not found" ) ]] ; then
	for i in "${https_p[@]}"; do
		if [[ $( cat ./https-curl${i}.txt | wc -l ) -lt 1000 ]] ; then 
			resp=$( cat ./https-wfuzz${i}.txt | grep "  200" )
			echo -e "\nHTTPS files on port ${i} returning 200 response (see https-wfuzz${i}.txt):\n${resp}\n" && if [[ $( cat ./https-curl${i}.txt | grep -E -- "login|admin|portal|robots" ) ]] ; then echo -e "Interesting Files on HTTPS port ${i}:\n$( cat ./https-curl${i}.txt | grep -E -- 'login|admin|portal|robots' )" ; fi
		fi
	done
fi


if [[ $( echo "${open_ps}" | grep "ftp" ) ]] ; then echo -e "FTPs present, anonymous login could be a thing...\n" ; fi
if [[ $( echo "${open_ps}" | grep "doom" ) ]] ; then echo -e "\nUnknown service is present, check this with telnet..." ; fi
if [[ $( echo "${open_ps}" | grep "ssh" ) ]] ; then echo -e "\nSSH present, check version for vulnerabilities (7.2p2 vulnerable to user enum, for example.)" ; fi
if [[ $( echo "${open_ps}" | grep "krb5" ) ]] ; then echo -e "\nKerberos authentication in place, relevant scripts:\n  getnpusers.py (check is users have dont require preauth set, asreproast)\n  getuserspns.py (kerberoast-harvest TGS tickets; requires knowledge of valid user)\n  kerbrute.py (brute force against Kerberos)\n  gettgt.py (pass the hash, requires valid user with specific permissions)" ; fi
if [[ $( echo "${open_ps}" | grep "ldap" ) ]] ; then echo -e "\nActive Directory runs on this machine, relevant scripts:\n  getadusers.py (reveal stats about users if there's alot to enumerate- e.g. last logon)\n  ldap-search.nse- nmap (perform an LDAP search and return found objects such as SMB shares and users)" ; fi
if [[ $( echo "${open_ps}" | grep -E -- "smb|microsoft-ds" ) ]] ; then 
	users=$( cat linux-enum.txt | grep -E -- "user:\[|Local User" ) 
	echo -e "Samba File Share present...Check ./linux-enum.txt for further information.\n  Check version for vulnerabilities and execute smb-vuln scripts with nmap (smb-vuln*)" 
	echo -e "\nLocal users discovered by enum4linux:\n${users}" 
	echo "Discovered shares:" ; echo $( cat linux-enum.txt | grep "Mapping: OK, Listing: OK" )
fi
exit 0
