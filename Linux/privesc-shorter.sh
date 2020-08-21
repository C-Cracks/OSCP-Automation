# reordered initial privesc script from low hanging fruit to more in-depth things
 
echo -e "\e[31mFiles run as group, not user:\e[0m" && find / -perm -g=s -type f 2>/dev/null
echo -e "\e[31mFiles run as owner, not user:\e[0m" && find / -perm -u=s -type f 2>/dev/null
# /bin/cp: can overwrite any file with a file of our choice- /etc/passwd is a good target

echo -e "\e[31mFiles with no owner:\e[0m" && find / -xdev \( -nouser -o -nogroup \) -print

echo -e "\e[31mWorld writeable files:\e[0m" && find / -writable 2>/dev/null
# e.g: writeable passwd=new root user
echo -e "\e[31mWorld executable files:\e[0m" && find / -perm -o x 2>/dev/null

echo -e "\e[31mFiles with sticky bit:\e[0m" && find / -perm -1000 -type d 2>/dev/null

crontab -l && echo "Other cronjob information:" && cat /etc/cron*

if [[ $( ps aux | grep "root" )!="" ]]; then echo "Services running under root: " ; ps aux | grep "root" ; fi 

# checked low hanging fruit- interesting SUID/SGID files, scheduled cronjobs, world writeable/executable and root processes.


# now gathering further info in case the above proves fruitless

# if an SMTP server -or similar- is present
echo -e "\e[31mMail directory\e[0m" && ls -al /var/mail

# if a web server is present, check for info leak (passes)
ls -al /var/www # not neccessarily here; it's the most common web server dir on Linux dists

# who else is on the system?
echo -e "\e[31mSystem users:\e[0m" && cat /etc/passwd | cut -d: -f1
ls -al /home

# any local services?
netstat -ano


