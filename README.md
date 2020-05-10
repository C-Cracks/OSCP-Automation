# OSCP-Automation
A collection of personal scripts used in hacking excercises.
https://c-cracks.tumblr.com/

## enum.sh
* Performs an Nmap scan on the provided IP and further Wfuzz and Nikto scans on discovered web servers (HTTP and HTTPS are treated as seperate entities as -realistically- one could hold vulnerabilities/directories the other doesn't)
* Very basic in nature and I'm sure there's more intuitive tools out there; I'm building my own collection of scan automation tools.

## privesc.sh
* Automation of info gathering for Linux privilege escalation
* Can be used even if upload to the victim isn't possible as a reference

## test-methods.sh
* Sends requests under different methods to the provided URL
* Appearance of the output leaves alot to be desired; as long as it's clear where each request ends I don't mind. xD

## brute-force.sh
* Brute force web applications with cURL
* Handles GET and POST requests currently with the options to add cookies and/or headers to the request
* POST has been tested thoroughly against the VM Mr Robot with the right credentials being discovered and I have also tested the addition of headers and/or cookies.
* Will likely discover issues with it as I use it so consider this script in beta. :)

## To come(?):
* privesc for Windows (eugh...)
  * This will likely come in a few weeks as I'll likely do this when I'm hacking a Windows machine.
* Improvements to enum.sh
  * Flag ports 5985 and 5986 (remote shell can be established through WinRM, reminder of evil-rm )
  * Flag kerberos service (Kerberoasting|ASREPRoasting|DC sync attacks for pass the hash - include Impacket scripts to use)
