#!/bin/bash

#Automation of part of the first step of enumeration- information gathering.
#Script performs nmap vulners scan, dirb based on the results of nmap and nikto based on the same
#Also performs a quick check for the existence of anonymous ftp access if relevant
#May add to this as time passes and I learn more

echo "C-Cracks\nEnumeration Automation\nServices and Web Servers"
ip=$1 && echo "Target: ${ip}\nCommencing with nmap vulners scan..."

nmap -oN ./nmap-scan-results.txt --script nmap-vulners -sV ${ip} -p- && notify-send 'Nmap Scan On ${ip} Complete' 'Results saved to nmap-scan-results.txt.'
cat ./nmap-scan-results.txt 

http_p=$( cat ./nmap-scan-results.txt | grep "http" | cut -d'/' -f 0 ) || echo "HTTP not found."
https_p=$( cat ./nmap-scan-results.txt | grep "https" | cut -d'/' -f 0 ) || echo "HTTPS not found."

ssh_p=$( cat ./nmap-scan-results.txt | grep "SSH" | cut -d'/' -f 0 ) || echo "SSH not found."
ftp_p=$( cat ./nmap-scan-results.txt | grep "ftp" | cut -d'/' -f 0 ) || echo "FTP not found."

http=1 ; https=1 ; ssh=1 ; ftp=1

case "not found" in 
	"${http_p}")
		$http-- ;;
	"${https_p}")
		$https-- ;;
	"${ssh_p}")
		$ssh-- ;;
	"${ftp_p}")
		$ftp-- ;;
	*)
# perform dirb scans
if $http -eq 1 & $https -eq 1; then 
	echo "Found HTTP and HTTPS, commencing with dirb..."
	timeout 360 dirb "http://${ip}:${http_p}" -o ./http-dirb.txt && notify-send 'Dirb Scan 1/2 On ${ip}:${http_p} Complete' 'Results saved to dirb.txt.'
	timeout 360 dirb "https://${ip}:${https_p}" -o ./https-dirb.txt && notify-send 'Dirb Scan 2/2 On ${ip}:${https_p} Complete' 'Results saved to dirb.txt.'
	cat http-dirb.txt https-dirb.txt > dirb.txt
elif $http -eq 0 & $https -eq 1; then 
	echo "Found HTTPS, commencing with dirb..."
	timeout 360 dirb "https://${ip}:${https_p}" -o ./dirb.txt && notify-send 'Dirb Scan On ${ip}:${https_p} Complete' 'Results saved to dirb.txt.'
elif $http -eq 1 & $https -eq 0; then 
	echo "Found HTTP, commencing with dirb..."
	timeout 360 dirb "http://${ip}:${http_p}" -o ./dirb.txt && notify-send 'Dirb Scan On ${ip}:${http_p} Complete' 'Results saved to dirb.txt.'
else echo "Did not find a web server..." && exit 1
fi

# curl found results
files=$( cat ./dirb.txt | grep -E -- "CODE:200|CODE:403|CODE:301|CODE:401|CODE:500" )

for v in "${files[@]}";do
	url=echo "${v}" | cut -d' ' -f 1 && curl "${url}" >> ./get-requests.txt > /dev/null 2>&1
done

notify-send 'Curl Requests on Dirb Results Complete' 'Results saved to get-requests.txt.' && cat ./get-requests.txt 

if "${ftp}" -eq 1;then
	echo "Now testing for anonymous access to FTP."
	ftp -n "${ip} ${ftp_p}" << EOF
		quote USER anonymous
		quote PASS b2p7Ua2
		quit
EOF
	if $? -ne 0;then echo "Anonymous login is not enabled."
	else echo "Anonymous login is enabled"
	fi
fi

# nikto sncans
if "${http}" -eq 1;then timeout 360 nikto -h "http://${ip}" -p "${http_p}" >> nikto-results.txt
elif "${https}" -eq 1;then timeout 360 nikto -h "https://${ip}" -p "${https_p}" >> nikto-results.txt
fi

notify-send 'Nikto Scans Complete' 'Results saved to nikto-requests.txt.' && cat ./nikto-results.txt 
echo "Initial enumeration complete" && ls -al |  grep -E -- "results|requests"
exit 0