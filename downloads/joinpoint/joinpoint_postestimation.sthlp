{smcl}
{*      *! version 1.1.1 2020-07-15}{...}
{vieweralsosee "joinpoint" "help joinpoint"}{...}

{hline}

{title:Title}

{phang}
There are two postestimation commands for {cmd:joinpoint}, {cmd:predict} and {cmd:joinpoint_plot}.


{title:Syntax}
{p 8 16 2}{cmd:predict} {newvarname}  {ifin}, [{it:options}]

{marker options}{...}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Options}
{synopt :{opt apc}}annual percent change{p_end}
{synopt :{opt ci(lci,uci)}}calculate confidence interval{p_end}
{synopt :{opt expxb}}exponentiate linear predictor{p_end}
{synopt :{opt nknots(#)}}predict for model with {it:#} knots{p_end}
{synopt :{opt regresspredict}}use {cmd:predict} for {cmd:regress} command{p_end}
{synopt :{opt stdp}}standard error of linear predictor{p_end}
{synopt :{opt xb}}linear predictor (default){p_end}


{title:Options}

{phang}
{opt apc} predict the annual percentage change (APC).

{phang}
{opt ci(lci,uci)} calculates confidence intervals for the APC.

{phang}
{opt expxb} exponentiates the linear predictor. When the outcome is a log(rate), this will give the predicted rate.

{phang}
{opt nknots(#)} perform the prediction for a model with {it:#} knots. The default is to predict for the best fitting model.

{phang}
{opt regresspredict} this will use the {cmd:predict} postestimation command of {cmd:regress} rather than the {cmd:predict} command of {cmd:joinpoint}.

{phang}
{opt stdp} will give the standard error of linear predictor.

{phang}
{opt stdp} will give the linear predictor.

{phang}
{cmd:joinpoint_plot}


{title:Syntax}
{p 8 16 2}{cmd:joinpoint_plot} {newvar}  {ifin}, [{it:options}]

{marker options}{...}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Options}
{synopt :{opt apc}}show apc summary text{p_end}
{synopt :{opt apcpos(#)}}position of apc summary text{p_end}
{synopt :{opt log}}log scale for yaxis{p_end}
{synopt :{opt *}}{it:other graph options}{p_end}
  



