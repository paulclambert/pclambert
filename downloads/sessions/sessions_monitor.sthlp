{smcl}
{* *! version 1  27aug2026}{...}
{viewerjumpto "Syntax" "sessions_monitor##syntax"}{...}
{viewerjumpto "Description" "sessions_monitor##description"}{...}
{viewerjumpto "Examples" "sessions_monitor##examples"}{...}
{p2colset 1 21 0 0}{...}
{p2col:{bf:sessions monitor} {hline 2}}Start and monitor multiple Stata sessions{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 21 2}
{cmd:sessions monitor} {ifin}, 
{opt dofiles(varname)}
{opt names(varname)} 
[{it:options}]

{marker options}{...}
{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt dof:iles(varname)}}variable containing names of dofiles(in years){p_end}
{synopt :{opt name:s(varname)}}variable containing names of Stata sessions{p_end}
{synopt :{opt arg:uments(varlist)}}variable(s) containing dofile arguments{p_end}
{synopt :{opt cpu:load(#)}}Only start session if cpu load<{it:#}{p_end}
{synopt :{opt common:do({it:files})}}dofiles to run in every session{p_end}
{synopt :{opt compress}}Compressed output{p_end}
{synopt :{opt detail}}Expanded output{p_end}
{synopt :{opt freemem:ory({#})}}Only start sessions if >{it:#}{p_end}
{synopt :{opt graphicson}}display graphics window{p_end}
{synopt :{opt logdelete}}delete existing logfile in _sessionslog folder{p_end}
{synopt :{opt maxsessions(#)}}maximum number of Stata sessions{p_end}
{synopt :{opt startg:ap(#)}}gap in seconds between starting Stats sessions{p_end}
{synopt :{opt startp:ath(folder)}}startingfolder in new Stata session{p_end}
{synopt :{opt update:time}}time in seconds between displaying update of progress{p_end}
{synopt :{opt wait:var(varname)}}variable detailing when to wait between starting sesssions{p_end}

{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
Using {cmd:session monitor} allows you to submit dofiles to different Stata sessions.

{pstd}
With {cmd:session monitor} you can:

{pmore}
Pass arguments to each do files

{pmore}
Run multiple Do files in each Session

{pmore}
Run common do files in all sessions

{pmore}
Wait for all preceding Sessions to complete

{pmore}
Select a subset of Sessons to run.

{pmore}
Specify the amount of free memory needed before starting a Stata session

{pmore}
Specify the CPU load required before starting a Stata session

{pmore}
Specify the maxiumum number of Stata sessions

{pmore}
Monitor if any Stata sessions exited with an error code and get immediate access to the corresponding log file.


{pstd}
To run the different Stata sessions you need to create a dataset that gives a name of each session, 
the do files to run in each session and any arguments that will be passed.
See the examples below for further details.

{pstd}
{cmd:session monitor} wil creater two folders, {it:_sessionsdo} and {it:_sessionslog}.
The {it:_sessionsdo} folder contains a short do files that are run within each Stata
session.
The {it:_sessionslog} folder contains the log file for each session.

{title:Options}

{p 2}
{bf:Compulsory options}

{phang}
{opt dofiles(varname)} where {it:varname} gives the path and filenames of the do files to run.
By default each new Stata session's starting folder is the current active Stata
folder, so it is not required to give the full path.

{phang}
{opt names(varname)} where {it:varname} gives the names of the Stata sessions.
You can send multiple do files to a Stata session if they have identical names.
If {it:varname} == "_wait_", then the subsequant Stata session will not start unless
all preceeding Stata sessions have completed. See example below.

{p 2}
{bf:Other options}

{phang}
{opt arguments(varlist)} where {it:varlist} gives the arguments to pass to the do files.
You can pass none or many arguments to a do file. Strictly, the number of arguements
passed to each do file is the same and equal to the the do file requiring the
largest number of arguements. However, a missing value / empty string means that 
an argument is not passed.

{phang}
{opt cpuload(#)} gives the percentage where a new Stata session will not start
unless the current CPU load is less than {it:#}. The default value is 75.

{phang}
{opt commondo(filelist)} gives any do files to be included in all sessions.
The do files will be run before the specified do files in the {cmd:dofiles()} option.
This is useful for specifying global macros that are consistent in all 
Stata sessions.

{phang}
{opt compress} lists the current status of the sessions without a divider.

{phang}
{opt detail} will list in the progress output all the dofiles sent to a Session 
rather than the default of just the session name.

{phang}
{opt freememory(#)} gives the percentage of free memory required before
a new Stata session starts. The default value is 25.

{phang}
{opt graphicson} will turn graphics display on. The default is to have 
{cmd: set graphics off} at the start of each new Stata sessions as they 
are being run in batch mode. 

{phang}
{opt logdelete} will delete all existing log files in the _sessionslog folder.
before the new Stata sessions are initiated. 

{phang}
{opt maxsessions(#)} give the maximum number of Stata sessions to be running 
simultaneously running. The number excludes the calling session.
The default value is 10. (CHANGE THIS????).

{phang}
{opt startgap(#)} give the time in seconds between starting Stata sessions.
The default is 1 second.

{phang}
{opt startpath(folder)} gives the starting path in the new Stata sessions.
The default is current working path.

{phang}
{opt updatetime(#)}} gives the time in seconds between display updates
of the progress of the different sessions.

{phang}
{opt waitvar(varname)} is an alternative to using the "_wait_" notation in the
Session name. When {it:varname}>0 that session will not start until all
preceeding sessions have completed.

{marker examples}{...}
{title:Examples}

To be added

{title:Author}

{pstd}
Paul C Lambert, Cancer Registry of Norway, NIPH, Norway & Karolinska Institutet, Sweden.
({browse "mailto:paul.lambert@fhi.no":paul.lambert@fhi.no})


  

