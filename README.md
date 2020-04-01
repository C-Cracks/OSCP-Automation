# OSCP-Automation
A collection of personal scripts used in hacking excercises.

## enum.sh
* Performs an Nmap scan on the provided IP and further Wfuzz and Nikto scans on discovered web servers (HTTP and HTTPS are treated as seperate entities as -realistically- one could hold vulnerabilities/directories the other doesn't)
* Very basic in nature and I'm sure there's more intuitive tools out there; I'm building my own collection of scan automation tools.

## privesc.sh
* Automation of info gathering for Linux privilege escalation
* Can be used even if upload to the victim isn't possible as a reference

## test-methods.sh
* Sends requests under different methods to the provided URL
* Appearance of the output leaves alot to be desired; as long as it's clear where each request ends I don't mind. xD

## To come(?):
* A brute force script for web application login pages utilizing cURL
* privesc for Windows (eugh...)
