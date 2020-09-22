/*
creating vars now to make the globally accessible
true if checked, false if not

Logic for when forms should appear or not currently works;

further logic required for text boxes if answers are yes and
for questions dependant on discovered services

*/
var linux,windows,web_s,file_s,rpcbind,sql_s,rdp;

var web_form=document.getElementById("web-f");
var file_form=document.getElementById("file-f");
var rpcbind_form=document.getElementById("rpcbind-f");
var sql_form=document.getElementById("sql-f");
var rdp_form=document.getElementById("rdp-f");
var smtp_form=document.getElementById("smtp-f");

var form1_b=document.getElementById("form1-sub");	var form2_b=document.getElementById("form2-sub");

form1_b.addEventListener('click', event => {
	linux=document.getElementById("linux").selected;
	windows=document.getElementById("windows").selected;
	/*alert(linux);*/
	web_s=document.getElementById("web-s").checked;
	file_s=document.getElementById("file-s").checked;
	rpcbind=document.getElementById("rpcbind").checked;
	sql_s=document.getElementById("sql-s").checked;
	rdp=document.getElementById("rdp").checked;
	smtp=document.getElementById("smtp").checked;

	if (web_s===true) { web_form.style="display:block;"; }
	if (file_s===true) { file_form.style="display:block;"; }
	if (rpcbind===true) { rpcbind_form.style="display:block;"; }
	if (sql_s===true) { sql_form.style="display:block;"; }
	if (rdp===true) { rdp_form.style="display:block;"; }
	if (smtp===true) { smtp_form.style="display:block;"; }

	form2_b.style="visibility:visible;";
});

form2_b.addEventListener('click', event => {
	if (linux===true)	{ document.getElementById("linux-f").style="display:block;";document.getElementById("win-f").style="display:none;"; }
	else if (windows===true)	{ document.getElementById("win-f").style="display:block;";document.getElementById("linux-f").style="display:none;"; }
});

/*
form1 gathers info on discovered services during nmap port scan
what is checked here will affect what questions appear later

if windows, include windows privesc prompts
else linux
this shouldd only appear after other enum




*/
