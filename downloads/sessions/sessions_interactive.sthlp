{smcl}
{* *! version 1  27aug2026}{...}
{viewerjumpto "Syntax" "sessions_monitor##syntax"}{...}
{viewerjumpto "Description" "sessions_monitor##description"}{...}
{viewerjumpto "Examples" "sessions_monitor##examples"}{...}
{p2colset 1 13 15 2}{...}
{p2col:{bf:sessions} {hline 2}}sessions (interactive commands){p_end}
{p2colreset}{...}



{pstd}
This list some {cmd:sessions} subcommands, however the most common (and useful) way 
to run sessions is to use {help sessions monitor}.


{p 8 21 2}
{cmd:sessions} [{opt init}] [stataexe(path)]{p_end}
{p 8 21 2}
Initialise sessions. This is required before running other sessions commands. 
The path to the Stata executable should be found automatically, but
use the {cmd:stataexe()} option if any problems.{p_end}

{p 8 21 2}
{cmd:sessions} {opt clear}{p_end}
{p 8 21 2}
Clear sessions.{p_end}

{p 8 21 2}
{cmd:sessions} {opt start} {it:dofile} {it:arguments}, [{cmd:,} ...]{p_end}
{p 8 21 2}
Start a new Stata session. You can name the session with the {cmd:name()} option, otherwise it will be named "Sessions#".
By default the Session is run in the background, you can use the {cmd:icon} option to display an icon for 
each session, but accidently opening it will pause the Stata run, so in most cases this is unnecessary.

{p 8 21 2}
{cmd:sessions} {opt kill} {#}{p_end}
{p 8 21 2}
Kill a session

{p 8 21 2}
{cmd:sessions} {opt list} {p_end}
{p 8 21 2}
List the sessions.

{p 8 21 2}
{cmd:sessions} {opt resources} {p_end}
{p 8 21 2}
Show system resources. This will display the number of logical processors,
the current CPU load (as a percentage, the current free memory (as a percentage)
and the number of active sessions. This numbers are available as return
stored results.

{p 8 21 2}
{cmd:sessions} {opt wait_for_resources},  [{cmd:,} ...]{p_end}
{p 8 21 2}

