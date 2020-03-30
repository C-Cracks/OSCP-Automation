#!/usr/bin/bash

#Automation of part of the first step of enumeration- information gathering.
#Script performs nmap vulners scan, dirb based on the results of nmap and nikto based on the same
#Also performs a quick check for the existence of anonymous ftp access if relevant
#May add to this as time passes and I learn more

# Just some fancy banner stuff 
figlet "C-Cracks" ; figlet "Initial Enum" ; echo "Services and Web Servers"
ip=$1 && echo -e "Target: ${ip}\nCommencing with nmap vulners scan..."

# perform Nmap scan on all ports using NSE script vulners
# Zenity creates alert boxes- removes the need to keep checking the terminal for output
nmap -oN ./nmap-scan-results.txt --script nmap-vulners -sV ${ip} -p-  > /dev/null 2>&1 && zenity --info --text="Nmap Scan On ${ip} Complete. Results saved to nmap-scan-results.txt."
cat ./nmap-scan-results.txt 

# collect relevant ports and place into variables for use later
http_p=$( cat ./nmap-scan-results.txt | grep "http" | grep -v "ssl" | cut -d'/' -f 1 | grep -v [A-Za-z] ) || echo "HTTP not found."
https_p=$( cat ./nmap-scan-results.txt | grep "ssl/http" | cut -d'/' -f 1 ) || echo "HTTPS not found."

ssh_p=$( cat ./nmap-scan-results.txt | grep "ssh" | cut -d'/' -f 1 ) || echo "SSH not found."
ftp_p=$( cat ./nmap-scan-results.txt | grep "ftp" | cut -d'/' -f 1 ) || echo "FTP not found."

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
esac
# perform wfuzz scans
if [[ "$http" -eq 1 ]] && [[ "$https" -eq 1 ]]; then 
	echo "Found HTTP and HTTPS, commencing with wfuzz..."
	timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:$http_p"/FUZZ > ./http-wfuzz.txt && zenity --info --text="Wfuzz on ${ip}:${http_p} Complete. Results saved to wfuzz.txt."
	timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:$https_p"/FUZZ > ./https-wfuzz.txt && zenity --info --text="Wfuzz on ${ip}:${https_p} Complete. Results saved to wfuzz.txt."
	cat http-wfuzz.txt https-wfuzz.txt > wfuzz.txt
	sort wfuzz.txt | uniq > wfuzz.txt
elif [[ "$http" -eq 0 ]] && [[ "$https" -eq 1 ]]; then 
	echo "Found HTTPS, commencing with wfuzz..."
	timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt https://"$ip:$https_p"/FUZZ > ./wfuzz.txt && zenity --info --text="Wfuzz on ${ip}:${https_p} Complete. Results saved to wfuzz.txt."
elif [[ "$http" -eq 1 ]] && [[ "$https" -eq 0 ]]; then 
	echo "Found HTTP, commencing with wfuzz..."
	timeout 360 wfuzz -w /usr/share/wordlists/dirb/common.txt http://"$ip:$http_p"/FUZZ > ./wfuzz.txt && zenity --info --text="Wfuzz on ${ip}:${http_p} Complete. Results saved to wfuzz.txt." 
else echo "Did not find a web server..." && exit 1
fi

# curl found results
cat wfuzz.txt | grep -v "404" | grep -o '".*"' | tr -d '"' > ./curl.txt

mkdir curl-requests && cd curl-requests || cd curl-requests
while IFS="" read -r p || [ -n "$p" ]
do
	url=$( echo "$p" | tr -d '\n' )
	if echo "$p" | grep -E -- "login|admin|portal|robots" > /dev/null 2>&1 ; then echo -e "\e[33m\e[1m$p\e[0m\e[33m may be interesting...\e[0m" ; fi

	if [[ "$http" -eq 1 ]]; then echo "HTTP" ; echo -e "$p\n" >> ./http-curl.txt && curl "http://${ip}:$http_p/$url/" >> ./http-curl.txt && echo -e "\n\n" >> ./http-curl.txt ; fi
	if [[ "$https" -eq 1 ]]; then echo "HTTPS" ; echo -e "$p\n" >> ./https-curl.txt && curl --insecure "https://${ip}:$https_p/$url/" >> ./https-curl.txt && echo -e "\n\n" >> ./https-curl.txt ; fi
done < ../curl.txt && zenity --info --text='Curl Requests on Dirb Results Complete. Results saved.'
cd ..
# nikto sncans
#echo "${ip} -p ${http_p}"
if [[ "${http}" -eq 1 ]];then nikto -h "${ip}:${http_p}" -nointeractive -maxtime 360 >> nikto-results.txt && zenity --info --text='Nikto HTTP Scan Complete. Results saved to nikto-requests.txt.'; fi
if [[ "${https}" -eq 1 ]];then nikto -h "${ip}:${https_p}" -nointeractive -maxtime 360 >> nikto-results.txt  && zenity --info --text='Nikto HTTPS Scan Complete. Results saved to nikto-requests.txt.' ; fi

cat ./nikto-results.txt 
if cat ./nikto-results.txt | grep -E -- "wordpress|WordPress|Wordpress" > /dev/null 2>&1 ; then echo "WordPress discovered, you should run WPScan." ; fi
echo "Initial enumeration complete" && ls -al |  grep -E -- "results|requests"
exit 0
