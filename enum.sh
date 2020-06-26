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
nmap -oN ./nmap-scan-results.txt -T4 -sV ${ip} -p-  > /dev/null 2>&1 && zenity --info --text="Nmap Scan On ${ip} Complete. Results saved to nmap-scan-results.txt."
cat ./nmap-scan-results.txt 

# collect relevant ports and place into variables for use later
# if more than 1 port returned, append to array, else continue with orig execution
http_p=( `cat ./nmap-scan-results.txt | grep "http" | grep -v "ssl" | grep -v "over" | grep -v "HTTPAPI" | cut -d'/' -f 1 | grep -v [A-Za-z] || echo "HTTP not found."` )
https_p=( `cat ./nmap-scan-results.txt | grep "ssl/http" | cut -d'/' -f 1 | grep -v [A-Za-z] || echo "HTTPS not found."` )

# run enum4linux against target if target is linux
if [[ $( cat nmap-scan-results.txt | grep -E -- "smb|windows" ) ]] ; then echo -e "\nRunning enum4linux..." ; enum4linux "${ip}" > linux-enum.txt ; cat linux-enum.txt ; fi

# perform wfuzz scans
if [[ $( echo "${http_p[@]}" | grep -v "not found" ) ]] && [[ $( echo "${https_p[@]}" | grep -v "not found" ) ]] ; then 
	echo "Found HTTP and HTTPS, commencing with wfuzz..."
	for i in "${http_p[@]}"; do
		timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ >> ./http-wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.txt >> ./http-wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.php >> ./http-wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.log >> ./http-wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.html >> ./http-wfuzz.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to wfuzz.txt." ; sleep 1
	done
	for i in "${https_p[@]}"; do
		timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ >> ./https-wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.txt >> ./https-wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.php >> ./https-wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.log >> ./https-wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.html >> ./https-wfuzz.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to wfuzz.txt." ; sleep 1
	done
	cat http-wfuzz.txt https-wfuzz.txt > wfuzz.txt
	
elif [[ $( echo "${http_p[@]}" | grep "not found" ) ]]  && [[ $( echo "${https_p[@]}" | grep -v "not found" ) ]] ; then 
	echo "Found HTTPS, commencing with wfuzz..."
	for i in "${https_p[@]}"; do
		timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ >> ./wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.txt >> ./wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.php >> ./wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.log >> ./wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.html >> ./wfuzz.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to wfuzz.txt." ; sleep 1
	done
	
elif [[ $( echo "${http_p[@]}" | grep -v "not found" ) ]] && [[ $( echo "${https_p[@]}" | grep "not found" ) ]]; then 
	echo "Found HTTP, commencing with wfuzz..."
	for i in "${http_p[@]}"; do
		timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ >> ./wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.txt >> ./wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.php >> ./wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.log >> ./wfuzz.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.html >> ./wfuzz.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to wfuzz.txt." ; sleep 1
	done
	
else echo "Did not find a web server..." && web_server="false"
fi

if ! [[ -v $web_server ]] ; then
	# curl found results
	cat wfuzz.txt | grep -v "404" | grep -o '".*"' | tr -d '"' | uniq > curl.txt

	if [[ $( cat ./curl.txt | wc -l ) -lt 1000 ]] ; then
		while IFS="" read -r p || [ -n "$p" ]
		do
			url=$( echo "$p" | tr -d '\n' )
			if echo "$p" | grep -E -- "login|admin|portal|robots" > /dev/null 2>&1 ; then echo -e "\e[33m\e[1m$p\e[0m\e[33m may be interesting...\e[0m" ; fi

			if [[ $( echo "${http_p[@]}" | grep -v "not found" ) ]] ; then
				for i in "${http_p[@]}"; do
					echo "HTTP port ${i}" ; echo -e "$p\n" >> ./http-curl.txt && curl "http://${ip}:${i}/$url/" >> ./http-curl.txt && echo -e "\n\n" >> ./http-curl.txt 
				done 
			fi
			
			if [[ $( echo "${https_p[@]}" | grep -v "not found" ) ]] ; then
				for i in "${https_p[@]}"; do
					echo "HTTPS port ${i}" ; echo -e "$p\n" >> ./https-curl.txt && curl --insecure "https://${ip}:${i}/$url/" >> ./https-curl.txt && echo -e "\n\n" >> ./https-curl.txt 
				done
			fi
		done < ./curl.txt && zenity --info --text='Curl Requests on Dirb Results Complete. Results saved.'
	else echo "1000+ pages found, skipping cURL (check wfuzz.txt manually.)"
	fi

	# nikto sncans
	echo -e "\nCommencing with Nikto Scans..."
	if [[ $( echo "${http_p[@]}" | grep -v "not found" ) ]]; then
		for i in "${http_p[@]}"; do 
			echo "no" | nikto -h "${ip}:${i}" -nointeractive -maxtime 360 >> nikto-results.txt && zenity --info --text='Nikto HTTP Scan Complete. Results saved to nikto-requests.txt.' 
		done
	fi
	if [[ $( echo "${https_p[@]}" | grep -v "not found" ) ]] ;then
		for i in "${https_p[@]}"; do
			echo "no" | nikto -h "${ip}:${i}" -nointeractive -maxtime 360 >> nikto-results.txt  && zenity --info --text='Nikto HTTPS Scan Complete. Results saved to nikto-requests.txt.' 
		done
	fi
fi

cat ./nikto-results.txt 
if cat ./nikto-results.txt | grep -E -- "wordpress|WordPress|Wordpress" > /dev/null 2>&1 ; then echo "WordPress discovered, you should run WPScan." ; fi
echo "Initial enumeration complete" && ls -al 

open_ps=$( cat ./nmap-scan-results.txt | grep "open" ) ; resp=$( cat ./wfuzz.txt | grep "  200" ) 
echo -e "\e[33m\e[1mRESULTS:\e[0m\e[33m\e[0m"
echo -e "Open Ports:\n${open_ps}" 
if [[ $( cat ./curl.txt | wc -l ) -lt 1000 ]] ; then echo -e "\nFiles returning 200 response (see wfuzz.txt if unsure on site.):\n${resp}\n" && if [[ $( cat ./curl.txt | grep -E -- "login|admin|portal|robots" ) ]] ; then echo -e "Interesting Files:\n$( cat ./curl.txt | grep -E -- 'login|admin|portal|robots' )\nSee wfuzz.txt for location of file." ; fi ; fi

if [[ $( echo "${open_ps}" | grep "ftp" ) ]] ; then echo -e "FTPs present, anonymous login could be a thing...\n" ; fi
if [[ $( echo "${open_ps}" | grep "doom" ) ]] ; then echo -e "\nUnknown service is present, check this with telnet..." ; fi
if [[ $( echo "${open_ps}" | grep "ssh" ) ]] ; then echo -e "\nSSH present, check version for vulnerabilities (7.2p2 vulnerable to user enum, for example.)" ; fi
if [[ $( echo "${open_ps}" | grep "krb5" ) ]] ; then echo -e "\nKerberos authentication in place, relevant scripts:\n  getnpusers.py (check is users have dont require preauth set, asreproast)\n  getuserspns.py (kerberoast-harvest TGS tickets; requires knowledge of valid user)\n  kerbrute.py (brute force against Kerberos)\n  gettgt.py (pass the hash, requires valid user with specific permissions)" ; fi
if [[ $( echo "${open_ps}" | grep "ldap" ) ]] ; then echo -e "\nActive Directory runs on this machine, relevant scripts:\n  getadusers.py (reveal stats about users if there's alot to enumerate- e.g. last logon)\n  ldap-search.nse- nmap (perform an LDAP search and return found objects such as SMB shares and users)" ; fi
if [[ $( echo "${open_ps}" | grep "smbd" ) ]] ; then 
	users=$( cat linux-enum.txt | grep -E -- "user:[|Local User" ) 
	echo -e "Samba File Share present...Check ./linux-enum.txt for further information.\n  Check version for vulnerabilities and execute smb-vuln scripts with nmap (smb-vuln*)" 
	echo -e "\nLocal users discovered by enum4linux:\n${users}" 
	echo "Discovered shares:" ; echo $( cat linux-enum.txt | grep "Mapping: OK, Listing: OK" )
fi
exit 0
