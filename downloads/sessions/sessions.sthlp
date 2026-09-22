{smcl}
{* *! version 1  27aug2026}{...}
{viewerjumpto "Syntax" "sessions##syntax"}{...}
{viewerjumpto "Description" "sessions##description"}{...}
{viewerjumpto "Examples" "sessions##examples"}{...}
{viewerjumpto "Stored results" "sessions##results"}{...}
{p2colset 1 13 15 2}{...}
{p2col:{bf:sessions } {hline 2}} Run multiple Stata sessions{p_end}
{p2colreset}{...}




{marker syntax}{...}
{title:Syntax}

{p 8 21 2}
{cmd:sessions monitor, } [{cmd:,} ...]

{p 8 21 2}
{cmd:sessions} {opt clear}

{p 8 21 2}
{cmd:sessions} {opt init} [{cmd:,} ...]

{p 8 21 2}
{cmd:sessions} {opt monitor} [{cmd:,} ...]

{p 8 21 2}
{cmd:sessions} {opt kill} # | {cmd:_all}

{p 8 21 2}
{cmd:sessions} {opt list} 

{p 8 21 2}
{cmd:sessions} {opt resources} 

{p 8 21 2}
{cmd:sessions} {opt start} [{cmd:,} ...]

{p 8 21 2}
{cmd:sessions} {opt wait_for_resources} [{cmd:,} ...]

{pstd}
The most common (and useful) way to run sessions is to use {help sessions monitor}

{pstd}
Occasionally you may want to add Stata sessions {help sessions interactive:interactively}

{pstd}
In both cases you will need to run {cmd:sessions init} to initialise the {cmd: sessions} set of commands.


{marker description}{...}
{title:Description}

{pstd}
The {cmd:sessions} command simplifies the process of running multiple Stata sessions.
The aim is take advantage of having multiple CPUs for "embarassingly parallel" problems.
An "embarassingly parallel" problem is when the tasks can be split into separate independent
tasks without the tasks needing to communicate.

{pstd}
Examples of when the {cmd: sessions} command may be useful. 

{pmore}
- Monte Carlo simulations where separate sessions can be used to analyse data
in different scenarios rather than looping over scenarios within the same
Stata session. 

{pmore}
- Running the same/similar analyses on different subgroups. For example,
for different types of cancer or for different regions/countries.


{marker examples}{...}
{title:Examples}


{title:Author}

{pstd}
Paul C Lambert, Cancer Registry of Norway, NIPH, Norway & Karolinska Institutet, Sweden.
({browse "mailto:paul.lambert@fhi.no":paul.lambert@fhi.no})


  
