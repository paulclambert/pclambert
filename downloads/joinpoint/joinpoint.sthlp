{smcl}
{*      *! version 1.1.1 2020-07-15}{...}
{vieweralsosee "regress" "help regress"}{...}
{vieweralsosee "joinpoint postestimation" "help joinpoint_postestimation"}{...}

{hline}

{title:Title}

{p2colset 5 18 10 2}{...}
{p2col :{hi:joinpoint} {hline 1}} Fit joinpoint models
{p2colreset}{...}

{title:Syntax}
{p 8 16 2}{cmd:joinpoint} {depvar} {it:indepvar} {ifin}, 
[{it:options}]

{marker options}{...}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Options}
{synopt :{opt apc(options)}}display annual percent change{p_end}
{synopt :{opt apc}}display annual percent change (default options){p_end}
{synopt :{opt bic}}model selection based on BIC (default){p_end}
{synopt :{opt bic3}}model selection based on BIC3{p_end}
{synopt :{opt knots(numlist)}}fit model with specific knots{p_end}
{synopt :{opt minintpoints(#)}}minimum number of points between knots{p_end}
{synopt :{opt minendpoints(#)}}minimum number of points before/after first/last knot{p_end}
{synopt :{opt savemodelfit}}save model fitting information{p_end}
{synopt :{opt se(varname)}}standard error of dependent variable{p_end}
{synopt :{opt verbose}}verbose output{p_end}
{synopt :{opt vuninflated}}use uninflated variance{p_end}
{synopt :{opt wbic}}model selection based on weighted BIC{p_end}

{p2colreset}{...}
{p 4 6 2}

{title:Description}

{pstd}
{cmd:joinpoint} fits joinpoint models. These models summarise trends using 
linear splines where the number and locations of knots are derived through
a model fitting algorithm. 
The models are usually used to summarise temporal trends in cancer incidence and mortality rates.

{pstd}
{cmd:joinpoint} fits similar models to the the {browse "https://surveillance.cancer.gov/joinpoint/":joinpoint} software developed
by the Surveillance Research Program , National Cancer Institute.

{pstd}
{cmd:joinpoint} will select a model using different model selection methods. 
All possible combinations of models are fitted for a maxiumum number of knots and
based on some restrictions on the minimum number of data points between knots and
before the first knot and after the last knot.

{title:Options}

{phang}
{opt apc} displays the annual percent change, which give the average percentage
increase or decrease in the rate over time. The default method to obtain
confidence intervals is to use the parametric method, i.e. based on the
the estimated standard errors displayed in the model.

{phang}
{opt apc(empirical samples(#))} changes the default method for caculating confidence intervals.

{phang2}
{opt empirical} Use the empirical quantile method to calculate confidence intervals, (Kim {it:et al.} 2017).

{phang2}
{opt samples(#)} Number of resamples used for empirical quantile method (default 20,000).

{phang}
{opt bic} will base model selection on the BIC. This is the default.

{phang}
{opt bic3} will base model selection on the BIC3, which has a harsher penalty term.. 

{phang} 
{opt knots(numlist)} will fit a single model with the specified knots. 
Most users will not need to use this option, but it is used by some of
the postestimation commands.

{phang}
{opt minintpoints(#)} gives the minimum number of data points between knots.
This number does not include the knots themselves. The default value is 5.

{phang}
{opt minendpoints(#)} gives the minimum number of data points before the first
and after the last knot. This number does not include the knots themselves.
The default value is 5.

{phang}
{opt savemodelfit} save details of every model fitted to a frame. These are
saved in frames names {bf:_knots1}, {bf:_knots2} etc.
Note that if these frames exist they will be overwritten.

{phang}
{opt se(varname)} give the estimated standard error of the outcome variable. 
When modelling rates this will usually be the standard error of the log(rate).
This option is not compulsory, but without it, it assumes that the standard errors
of the (log) rates are homogeneous.

{phang}
{opt verbose} give more detailed output.

{phang}
{opt vuninflated} use uninflated variance. This will use the variance estimate without inflating (by fitting the
an unconstrained model). Generally, it is not recommended to use this option
as standard errors will be too small.

{phang}
{opt wbic} will base model selection on the weighted BIC. 
This combines BIC and BIC3 using a weighted penalty term based on the data (Kim {it:et al} 2022).
  


{title:Example}

{pstd}
The example uses an NIH example data set (available from here).
The example is clickable, but you will need to clear data in memory before running. 

{phang}
Load the data

{pmore}
{stata "import delimited https://pclambert.net/data/nih_sample_data.csv":use "import delimited https://pclambert.net/data/nih_sample_data.csv"}{p_end}

{phang}
Restrict analysis to males

{pmore}
{stata `"keep if sex=="Male""':keep if sex=="Male"}

{phang}
Calculate log rate and standard error.
 
{pmore}
{stata "gen lnrate = ln(rate)":gen lnrate = ln(rate)}

{pmore}
{stata "gen lnse = se/rate":gen lnse = se/rate}

{phang}
Scatter plot of the data.

{pmore}
{stata "scatter rate year, yscale(log)":scatter rate year, yscale(log)}

{phang}
Run {cmd:joinpoint} for models with between 0 and 5 knots. Display the annual percentage change (APC).

{pmore}
{stata "joinpoint lnrate year, se(lnse) nknots(0(1)5) apc":joinpoint lnrate year, se(lnse) nknots(0(1)5) apc}

{phang}
Plot the best fitting model with APC estimates.

{pmore}
{stata "joinpoint_plot, apc apcpos(7)":joinpoint_plot, apc apcpos(7)}

{phang}
Compare to  model with 1 knot.

{pmore}
{stata "joinpoint_plot, nknots(1) apc apcpos(7)":joinpoint_plot, nknots(1) apc apcpos(7)}

{phang}
Run a joinpoint model with a minimum of 3 obervations between the knots,
and before the first and after the last knot. 
Use the weighted BIC to select models and obtain empirical confidence intervals for the APC.

{pmore}
{stata "joinpoint lnrate year, se(lnse) nknots(0(1)5) apc(empirical) minintpoints(3) minendpoints(3) wbic":joinpoint lnrate year, se(lnse) nknots(0(1)5) apc(empirical) minintpoints(3) minendpoints(3) wbic}

{title:Stored results}

{pstd}
In addition to the {cmd:ereturn} reults stored by regress the following are stored.


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(bestknots)}}Number of knots for the best fitting model{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(sevar)}}Variable containing standard error{p_end}
{synopt:{cmd:e(xvar)}}X variable{p_end}
{synopt:{cmd:e(yvar)}}Y variable{p_end}
{synopt:{cmd:e(nknots)}}Number of knots (passed using nknots() option).{p_end}
{synopt:{cmd:e(BIC_#)}}BIC for model with # knots{p_end}
{synopt:{cmd:e(BIC3_#)}}BIC3 for model with # knots{p_end}
{synopt:{cmd:e(WBIC3_#)}}Weighted BIC for model with # knots{p_end}
{synopt:{cmd:e(bestknots#)}}Knot positions for model with # knots{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(V_uninflated)}}Variance for model before inflating by fitting unconstrained model{p_end}
{synopt:{cmd:e(apc)}}APC estimates and 95% confidence intervals{p_end}

{title:Author}

{pstd}
Paul C Lambert, Cancer Registry of Norway, NIPH, Norway & Karolinska Institutet, Sweden.
({browse "mailto:paul.lambert@fhi.no":paul.lambert@fhi.no})

{title:Acknowledgement}

{pstd}
This command implements many of the methods developed for and implemented in the
{browse "https://surveillance.cancer.gov/joinpoint/":joinpoint} software developed
by the Surveillance Research Program , National Cancer Institute, which
was very useful during development.

{title:References}

{phang}
Kim HJ, Chen HS, Byrne J, Wheeler B, Feuer EJ.
Twenty Years since Joinpoint 1.0: Two Major Enhancements, Their Justification, and Impact. {it:Statistics in Medicine} 2022:{bf:41};3102-3130

{phang}
Kim HJ, Fay MP, Feuer EJ, Midthune DN. Permutation tests for joinpoint regression with applications to cancer rates. 
{it:Statistics in Medicine} 2000;{bf:19};335-51. 
Erratum in : Stat Med 2001 Feb 28; 20(4):655

{phang}
Kim HJ, Luo J, Chen HS, Green D, Buckman B, Byrne J, Feuer EJ. Improved confidence interval for average annual percent change in trend analysis. {it:Statistics in Medicine} 2017;{bf:36}:3059-3074
