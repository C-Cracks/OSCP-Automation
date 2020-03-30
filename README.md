# OSCP-Automation
A collection of personal scripts used in hacking excercises.

## enum.sh
* Performs an Nmap scan on the provided IP and further Wfuzz and Nikto scans on discovered web servers (HTTP and HTTPS are treated as seperate entities as -realistically- one could hold vulnerabilities/directories the other doesn't)

* Very basic in nature and I'm sure there's more intuitive tools out there; I'm building my own collection of scan automation tools.

## To come(?):
* A brute force script for web application login pages utilizing cURL
* HTTP(S) method testing
* privesc? (maybe; unsure on if this is needed... Might though!)
