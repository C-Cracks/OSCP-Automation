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
nmap -oN ./nmap-scan-results.txt -sV -Pn ${ip} -p- && zenity --info --text="Nmap Scan On ${ip} Complete. Results saved to nmap-scan-results.txt." || echo "Try appending -Pn flag to nmap command- might be blocking ping probes."
cat ./nmap-scan-results.txt 

# collect relevant ports and place into variables for use later
# if more than 1 port returned, append to array, else continue with orig execution
http_p=( `cat ./nmap-scan-results.txt | grep -i "http" | grep -v -i "ssl" | grep -v -i "over" | grep -v -i "HTTPAPI" | cut -d'/' -f 1 | grep -v [A-Za-z] || echo "HTTP not found."` )
https_p=( `cat ./nmap-scan-results.txt | grep -i "ssl/http" | cut -d'/' -f 1 | grep -v [A-Za-z] || echo "HTTPS not found."` )
smb_p=( `cat ./nmap-scan-results.txt | grep -E -i -- "smb|microsoft-ds" | cut -d'/' -f 1 | grep -v [A-Za-z] || echo "SMB not found"` )
# run enum4linux against target if target is linux

if [[ $( cat ./nmap-scan-results.txt | grep -E -i -- "smb|microsoft-ds" ) ]]; then
	echo -e "\nRunning enum4linux..." ; timeout 300s enum4linux "${ip}" > linux-enum.txt ; cat linux-enum.txt
	echo -e "\nScanning for SMB vulnerabilities..." ; nmap -oN ./nmap-smb-vulns.txt --script smb-vuln* ${ip} -pU:139,T:445 -Pn && cat nmap-smb-vulns.txt
	echo "Check that the right port was scanned for SMB vulns."
fi

https=$( echo "${https_p[@]}" | grep "not found" )
http=$( echo "${http_p[@]}" | grep "not found" )
# perform wfuzz scans

if [[ -z "$https" ]]; then 
	echo "Found HTTPS, commencing with GoBuster..."
	for i in "${https_p[@]}"; do
		#timeout 360 dirb "https://$ip:$i/" /usr/share/wordlists/dirb/common.txt -x exts -o https-gob$i.txt
		timeout 360 gobuster dir -r -u "https://$ip:$i/" -w /usr/share/wordlists/dirb/common.txt -t 40 -x .html,.txt > https-gob$i.txt
		#timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ >> ./https-gob${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.txt >> ./https-gob${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.php >> ./https-gob${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.log >> ./https-gob${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:${i}"/FUZZ.html >> ./https-gob${i}.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to https-gob${i}.txt." ; sleep 1
	done
fi
	
if [[ -z "$http" ]]; then 
	echo "Found HTTP, commencing with GoBuster..."
	for i in "${http_p[@]}"; do
		timeout 360 gobuster dir -r -u "http://$ip:$i/" -w /usr/share/wordlists/dirb/common.txt -t 40 -x .html,.txt > http-gob$i.txt
		#timeout 360 dirb "http://$ip:$i/" /usr/share/wordlists/dirb/common.txt -x exts -o http-gob$i.txt
		#timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ >> ./http-gob${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.txt >> ./http-gob${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.php >> ./http-gob${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.log >> ./http-gob${i}.txt && timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:${i}"/FUZZ.html >> ./http-gob${i}.txt && zenity --info --text="Wfuzz on ${ip}:${i} Complete. Results saved to http-gob${i}.txt." ; sleep 1
	done
fi
	
if [[ ! -z "$http" ]] && [[ ! -z "$https" ]]; then echo "Did not find a web server..."; fi

if [[ -z "$http" ]] || [[ -z "$https" ]]; then
	# curl found results

	if [[ -z "$http" ]]; then
		for i in "${http_p[@]}"; do
			sed -i '1,14d' http-gob${i}.txt
			cat http-gob$i.txt | head -n -3 | cut -d'/' -f 2 | cut -d' ' -f 1 | sort -u > ./http-curl${i}.txt
			sed -i '1,1d' http-curl${i}.txt
			#cat http-gob${i}.txt | grep -v "404" | grep -o '".*"' | tr -d '"' | sort -u > ./http-curl${i}.txt
			if [[ $( cat ./http-curl${i}.txt | wc -l ) -lt 1000 ]] && [[ $( cat ./http-curl${i}.txt | wc -l ) -gt 0 ]] ; then
				while IFS="" read -r p || [ -n "$p" ] ; do
					url=$( echo "$p" | tr -d "\n" )
					echo "HTTP port ${i}" >> ./http-curl.txt ; echo -e "$p\n" >> ./http-curl.txt && curl "http://${ip}:${i}/$url/" >> ./http-curl.txt && echo -e "\n\n" >> ./http-curl.txt
					if echo "$p" | grep -E -- "login|admin|portal|robots" > /dev/null 2>&1 ; then echo -e "\e[33m\e[1m$p\e[0m\e[33m on HTTP port ${i} may be interesting...\e[0m" ; fi
				done < ./http-curl${i}.txt && zenity --info --text="HTTP port ${i} cURL Requests on GoBuster Results Complete. Results saved."
			else echo "1000+ pages found or none at all, skipping cURL (check http-gob${i}.txt manually.)"
			fi
		done
	fi

	if [[ -z "$https" ]]; then

		for i in "${https_p[@]}"; do
			sed -i '1,14d' https-gob${i}.txt
			cat https-gob$i.txt | head -n -3 | cut -d'/' -f 2 | cut -d' ' -f 1 | sort -u > ./https-curl${i}.txt
			sed -i '1,1d' https-curl${i}.txt
			#cat https-gob${i}.txt | grep -v "404" | grep -o '".*"' | tr -d '"' | sort -u > ./https-curl${i}.txt
			if [[ $( cat ./https-curl${i}.txt | wc -l ) -lt 1000 ]] && [[ $( cat ./http-curl${i}.txt | wc -l ) -gt 0 ]] ; then
				while IFS="" read -r p || [ -n "$p" ] ; do
					url=$( echo "$p" | tr -d '\n' )
					echo "HTTPS port ${i}" >> ./https-curl.txt ; echo -e "$p\n" >> ./https-curl.txt && curl --insecure "https://${ip}:${i}/$url/" >> ./https-curl.txt && echo -e "\n\n" >> ./https-curl.txt
					if echo "$p" | grep -E -- "login|admin|portal|robots" > /dev/null 2>&1 ; then echo -e "\e[33m\e[1m$p\e[0m\e[33m on HTTPS port ${i} may be interesting...\e[0m" ; fi
				done < ./https-curl${i}.txt  && zenity --info --text="HTTPS port ${i} cURL Requests on GoBuster Results Complete. Results saved."
			else echo "1000+ pages found or none at all, skipping cURL (check https-gob${i}.txt manually.)"
			fi
		done
	
	fi

	# nikto sncans
	echo -e "\nCommencing with Nikto Scans..."
	if [[ -z "$http" ]]; then
		for i in "${http_p[@]}"; do 
			echo "no" | nikto -h "${ip}:${i}" -nointeractive -maxtime 360 >> nikto-results.txt && zenity --info --text="Nikto HTTP Scan for port ${i} Complete. Results saved to nikto-requests.txt."
		done
	fi
	if [[ -z "$https" ]]; then
		for i in "${https_p[@]}"; do
			echo "no" | nikto -h "${ip}:${i}" -nointeractive -maxtime 360 >> nikto-results.txt  && zenity --info --text="Nikto HTTPS Scan for port ${i} Complete. Results saved to nikto-requests.txt."
		done
	fi
	cat ./nikto-results.txt 
	if [[ $( cat ./nikto-results.txt | grep -E -- "wordpress|WordPress|Wordpress" ) ]] ; then echo "WordPress discovered, you should run WPScan." ; fi
fi

echo "Initial enumeration complete" && ls -al 

open_ps=$( grep "open" ./nmap-scan-results.txt )  
echo -e "\e[33m\e[1mRESULTS:\e[0m\e[33m\e[0m"
echo -e "Open Ports:\n${open_ps}" 
echo -e "Open Ports:\n${open_ps}" > notes

if [[ -z "$http" ]]; then
	for i in "${http_p[@]}"; do
		resp=$( cat ./http-gob${i}.txt | grep "200" )
		if [[ $( cat ./http-curl${i}.txt | wc -l ) -lt 1000 ]] ; then
			echo -e "\nHTTP files on port ${i} returning 200 response (see http-gob${i}.txt):\n${resp}\n" && if [[ $( cat ./http-curl${i}.txt | grep -E -- "login|admin|portal|robots" ) ]] ; then echo -e "Interesting Files on HTTP port ${i}:\n$( cat ./http-curl${i}.txt | grep -E -- 'login|admin|portal|robots' )" ; fi 
		fi
	done
fi

if [[ -z "$https" ]]; then
	for i in "${https_p[@]}"; do
		resp=$( cat ./https-gob${i}.txt | grep "200" )
		if [[ $( cat ./https-curl${i}.txt | wc -l ) -lt 1000 ]] ; then 
			echo -e "\nHTTPS files on port ${i} returning 200 response (see https-gob${i}.txt):\n${resp}\n" && if [[ $( cat ./https-curl${i}.txt | grep -E -- "login|admin|portal|robots" ) ]] ; then echo -e "Interesting Files on HTTPS port ${i}:\n$( cat ./https-curl${i}.txt | grep -E -- 'login|admin|portal|robots' )" ; fi
		fi
	done
fi


if [[ $( echo "${open_ps}" | grep -i "ftp" ) ]] ; then echo -e "FTPs present, anonymous login could be a thing...\n" ; fi
if [[ $( echo "${open_ps}" | grep -i "doom" ) ]] ; then echo -e "\nUnknown service is present, check this with telnet..." ; fi
if [[ $( echo "${open_ps}" | grep -i "ssh" ) ]] ; then echo -e "\nSSH present, check version for vulnerabilities (7.2p2 vulnerable to user enum, for example.)" ; fi
if [[ $( echo "${open_ps}" | grep -i "krb5" ) ]] ; then echo -e "\nKerberos authentication in place, relevant scripts:\n  getnpusers.py (check is users have dont require preauth set, asreproast)\n  getuserspns.py (kerberoast-harvest TGS tickets; requires knowledge of valid user)\n  kerbrute.py (brute force against Kerberos)\n  gettgt.py (pass the hash, requires valid user with specific permissions)" ; fi
if [[ $( echo "${open_ps}" | grep -i "ldap" ) ]] ; then echo -e "\nActive Directory runs on this machine, relevant scripts:\n  getadusers.py (reveal stats about users if there's alot to enumerate- e.g. last logon)\n  ldap-search.nse- nmap (perform an LDAP search and return found objects such as SMB shares and users)" ; fi

if [[ $( cat ./nmap-scan-results.txt | grep -E -i -- "smb|microsoft-ds" ) ]] ; then 
	users=$( cat linux-enum.txt | grep -E -- "user:\[|Local User" ) 
	echo -e "Samba File Share present...Check ./linux-enum.txt for further information.\n  Check version for vulnerabilities and execute smb-vuln scripts with nmap (smb-vuln*)" 
	echo -e "\nLocal users discovered by enum4linux:" ; echo "${users}" ; echo "" 
	echo "Discovered shares:" ; echo $( cat linux-enum.txt | grep "Mapping: OK, Listing: OK" )
	if [[ $( grep "VULNERABLE" nmap-smb-vulns.txt ) ]] ; then echo "Known SMB vulns are present, check nmap-smb-vulns.txt" ; fi
fi

if [[ $( echo "${open_ps}" | grep -i "ms-wbt-server" ) ]] ; then echo -e "RDP present- brute force attack via ncrack or crowbar." ; fi
if [[ $( echo "${open_ps}" | grep -i "Apache" ) ]] ; then echo -e "Apache means\n   CGI/Perl\n   PHP\n   Python\nPay special interest to cgi-bin files (ShellShock).\n   timeout 360 gobuster dir -r -u https://$ip:$i/ -w /usr/share/wordlists/dirb/common.txt -t 40 -x .pl,.cgi,.php,.bash,.sh" ; fi
if [[ $( echo "${open_ps}" | grep -i "xampp" ) ]] ; then echo "XAMPP is a Windows implementation of Apache, means\n    PHP\n   Perl\n   MySQL\n   Python (less likely but possible)\n   timeout 360 gobuster dir -r -u https://$ip:$i/ -w /usr/share/wordlists/dirb/common.txt -t 40 -x .php,.pl,.cgi,.py" ; fi
if [[ $( echo "${open_ps}" | grep -i "IIS" ) ]] ; then echo -e "IIS could support\n   ASP/ASPX\n   CGI/Perl\n   Java\n   timeout 360 gobuster dir -r -u https://$ip:$i/ -w /usr/share/wordlists/dirb/common.txt -t 40 -x .asp,.aspx,.pl,.jsp,.cgi" ; fi
if [[ $( echo "${open_ps}" | grep -i "nginx" ) ]] ; then echo -e "NGINX found.\nThere could be\n   Perl\n   PHP\n   Python\n   Node\n   Go\n   Ruby\n   Java Servlet\n   timeout 360 gobuster dir -r -u https://$ip:$i/ -w /usr/share/wordlists/dirb/common.txt -t 40 -x .pl,.go,.py,.php
" ; fi

exit 0
