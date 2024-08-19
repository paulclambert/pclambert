program define stpm3calplot, rclass
  syntax [varlist(default=none)]                                        ///
                    [if] [in],     [                                    ///
                                   CIObs                                ///
                                   CIPred                               ///
                                   CUT(numlist ascending)               ///
                                   FACtor                               ///
                                   FRame(string)                        ///
                                   PSEUDOFrame(string)                  ///
                                   GRoups(integer 0)                    ///
                                   PITime(string)                       ///
                                   PSeudo                               ///
                                   RANge(numlist ascending min=2 max=2) ///
                                   RUNNINGOPTs(string)                  ///
                                   SMoother(string)                     ///
                                   SMOOTHERCI                           ///
                                   STATs(string)                        ///
                                   TIME(real 0)                         ///
                                   *                                    ///
                                   ]                    

  if "`e(cmd)'" != "stpm3" {
    di as error "An stpm3 model has not been fitted."
    exit 198
  } 
  marksample touse
  
  local failure failure
  if "`factor'" != "" & `groups' != 0 {
    di as error "You cannot use the groups() optons with factor variables."
    exit 198
  }
  
  if `groups' != 0 & "`cut'" != "" {
    di as error "only specify one of the groups() or cut() options."
    exit 198
  }
    
  if "`anything'" != "" & "`pseudo'" != "" {
    di as error "You cannot use the pseudo option when specifiying covariates"
    exit 198
  }  

  
  if "`smoother'" != "" & "`pseudo'" == "" {
    di as error "Only use smoother() option when using pseudo option."
    exit 198
  }
    
    
  // default 10 groups
  if `groups' == 0 local groups 10

  local egenopt = cond("`cut'"!="","at(`cut')","group(`groups')")
  
  // Prognostic index
  if "`varlist'" == "" {
    if "`e(tvc)'" != "" & "`pitime'" == "" {
      di as error "The stpm3 model has time-dependent effects, so the prognostic index"
      di as error "varies over time. Use the {cmd:pitime()} option to specify a time point" 
      exit 198
    }
        tempvar PI TPI
    if "`pitime'" == "" {
      qui predict `PI' if `touse', xbnotime merge
    }
    else {
      gen `TPI' = `pitime' if `touse'
      qui predict `PI' , xb timevar(`TPI') merge      
    }
          local haspi haspi
          local varlist `PI'
  }
  
  if "`factor'" == "" {
        tempvar vgrp
    qui egen `vgrp' = cut(`varlist') if `touse', `egenopt' icodes
    qui replace `vgrp' = `vgrp' + 1 if `touse'
    qui levelsof `vgrp' if `touse'
    local Ngroups `r(r)'
    local levels `r(levels)'
  }
  else {
    qui levelsof `varlist' if `touse'
    local levels `r(levels)'
    local Ngroups `r(r)'
    local vgrp `varlist'
  }
        
  tempvar tt
    
  qui gen `tt' = `time' in 1 
  //local predtype = cond("`failure'" != "","failure","survival")
  local atstub = cond("`failure'" != "","F","S")
 
// frame options
  Getframeoptions `frame',
  if "`framename'" == "" {
    tempname tempframe
    local framename `tempframe'
  }
  Getpseudoframeoptions `pseudoframe',
  

// Obtain marginal estimates  
  foreach i in `levels' {
    local atlist `atlist' `atstub'`i'
  }

  if "`cipred'" != "" local standsurvci ci
  qui standsurv , failure timevar(`tt')       ///
                   over(`vgrp')  atvar(`atlist')  ///
                   `standsurvci'                  ///
                   frame(`framename') 
                                   
  frame `framename' {
     if "`cipred'" != "" {
       rename `atstub'*_lci `atstub'_lci*
       rename `atstub'*_uci `atstub'_uci*
       local atsub_ci `atstub'_lci `atstub'_uci
     }
     qui reshape long `atstub' `atsub_ci', i(`tt') j(group) 
  }
  
  tempfile stsresults 
  qui sts list if `touse', failure by(`vgrp') risktable(`time') saving(`stsresults')

  tempname stsframe
  frame create `stsframe'
  frame `stsframe' {
    use `stsresults'
    rename `vgrp' group
    local KMtype failure
    rename `KMtype' KM
    keep group KM lb ub
  }
  
  frame `framename' {
    qui frlink 1:1 group, frame(`stsframe')
    qui frget KM lb ub, from(`stsframe')
  }
  
// stratified pseudo observations
  if "`pseudo'" != "" {
    tempvar pseudo temppo
    qui gen `pseudo' = .        
    qui levels `vgrp'
    foreach i in `r(levels)' {      
      local stpsurv_type = cond("`failure'" != "","failure","")
      qui stpsurv if `vgrp'==`i' & `touse', at(`time')  gen(`temppo') `stpsurv_type'
      qui replace `pseudo' = `temppo' if `vgrp' == `i' & `touse'
      drop `temppo'
    }
    if "`smoother'" == "" local smoother running

    tempvar pred tlong
    gen `tlong' = `time' if `touse'
    qui predict `pred' if `touse', failure timevar(`tlong') merge
  }

// produce plot  
  if "`ciobs'" != "" {
    local ciobs (rspike ub lb `atstub', pstyle(p2line) mcolor(%50))
  }
  
  if "`cipred'" != "" {
    local cipred (rspike `atstub'_lci `atstub'_uci KM, pstyle(p2line) horizontal  mcolor(%50))
  }
  if "`range'" == "" {
    local xymin 0 
    local xymax 1
  }
  else {
    xymin = word("`range'",1)
    xymax = word("`range'",2)
  }
  local xyscale xscale(range(`xymin' `xymax')) yscale(range(`xymin' `xymax'))
  
  
   _get_gropts, graphopts(`options') getallowed(legend xtitle ytitle title)
   if `"`legend'"' == "" local legend(off)
  
  
  frame `framename' {
    twoway (function y = x, range(`xymin' `xymax') pstyle(p1line) lpattern(dash)) ///
           (scatter KM `atstub', msymbol(Oh))                                     ///
           `ciobs' `cipred'                                                       ///
          ,legend(off)                                                            ///
          ytitle("Observed")                                                      ///
          xtitle("Predicted")                                                     ///
          ylabel(,format(%3.1f))                                                  ///
          xlabel(,format(%3.1f))                                                  ///
          `xyscale'                                                               ///
          aspectratio(1)                                                          ///
          `options'
  }  
  
  tempvar po_pred po_pred_se po_pred_lci po_pred_uci
  if "`smoother'" == "running" {
    if "`smootherci'" != "" {
      local runningopts `runningopts' gense(`po_pred_se')
    }
    else {
      local runningopts `runningopts' repeat(2)
    }
    qui running `pseudo' `pred' if `touse', nograph generate(`po_pred') `runningopts' 
    qui replace `po_pred' = . if !inrange(`po_pred',0,1) & `touse'
    if "`smootherci'" != "" {
      local Z =  abs(invnormal((1-(`c(level)'/100))/2))
      qui gen `po_pred_lci' = `po_pred' - `Z'*`po_pred_se' 
      qui replace `po_pred_lci' = 0 if `po_pred_lci'<0 & `touse'
      qui gen `po_pred_uci' = `po_pred' + `Z'*`po_pred_se'
      qui replace `po_pred_uci' = 1 if `po_pred_uci'>1 & `touse'
      addplot: (rarea `po_pred_lci' `po_pred_uci' `pred', sort color(%30) norescaling pstyle(p3line)) 
    }
    addplot: (line `po_pred' `pred', sort pstyle(p3line) norescaling)
    
 
  }
  if "`smoother'" == "ns" {
    tempvar po_pred po_pred_se po_pred_lci po_pred_uci
    tempname currentmodel
    local Z =  abs(invnormal((1-(`c(level)'/100))/2))
    local glmdf 5 // ********** make option **************
    gensplines `pred' if `touse', type(rcs) df(`glmdf') gen(___bs)
    est store `currentmodel'
    capture glm `pseudo' ___bs* if `touse', link(logit) robust
    if _rc {
      di as error "Problem fitting glm model"
      qui est restore `currentmodel'
      capture drop ___bs*
      exit 198
    }
    qui predict `po_pred' if `touse'
    if "`smootherci'" != "" {
      qui predict `po_pred_se' if `touse', stdp
      qui gen `po_pred_lci' = invlogit(logit(`po_pred') - 1.96*`po_pred_se') if `touse'
      qui gen `po_pred_uci' = invlogit(logit(`po_pred') + 1.96*`po_pred_se') if `touse'
      addplot: (rarea `po_pred_lci' `po_pred_uci' `pred', sort color(%30) norescaling pstyle(p3line)) 
    }
    addplot: (line `po_pred' `pred', sort pstyle(p3line) norescaling)
    
    capture drop ___bs*
    capture qui est restore `currentmodel'
  }
  
  // performance statistics
  if "`stats'" != "" {
    foreach ps in `stats' {
      if !inlist("`ps'","brier","auc","calint","calslope") { // available statistics
        di as error "Unrecognised statistic"
        exit 198
      }
      stpm3calplot_stats , stat(`ps') pseudo(`pseudo') pred(`pred') `failure'
      local statfmt: di %5.4f `stat_`ps''
      
      if "`ps'" == "brier"    local addtext "Brier Score: "
      if "`ps'" == "auc"      local addtext "AUC: "
      if "`ps'" == "calint"   local addtext "Calibration Intercept: "
      if "`ps'" == "calslope" local addtext "Calibration Slope: "
      
      local text1 `"`text1' "`addtext'`statfmt'""'
      return local `ps' `stat_`ps''
      capture qui est restore `currentmodel'

    }
    addplot: , text(1 0.6 `text1', place(7) just(right))
  }
  
  
  
  if "`pseudoframename'" != "" {
    frame put `pseudo' `pred' `po_pred' `po_pred_lci' `po_pred_uci' `pseudoframekeep' if `touse', into(`pseudoframename')
    
    frame `pseudoframename' {
      desc
      rename `pseudo' PO
      rename `pred' F`time'
      rename `po_pred' PO_pred
      rename `po_pred_lci' PO_pred_lci
      rename `po_pred_uci' PO_pred_uci
    }
  }     

end

program define Getframeoptions
  syntax [anything], [replace]
  if "`anything'" == "" exit
  
  local framename `anything'
  if "`framename'" != "" {
    mata: st_local("frameexists",strofreal(st_frameexists(st_local("framename"))))
    if `frameexists' & "`replace'" == "" {
      di as error "Frame `frame' exists."
      exit 198
    }
    else if "`replace'" != "" {
      capture frame drop `framename'
    }
  }  
  
  c_local framename `framename'
end

program define Getpseudoframeoptions
  syntax [anything], [replace keep(varlist)]
  if "`anything'" == "" exit
  
  local pseudoframename `anything'
  if "`pseudoframename'" != "" {
    mata: st_local("frameexists",strofreal(st_frameexists(st_local("pseudoframename"))))
    if `frameexists' & "`replace'" == "" {
      di as error "Frame `frame' exists."
      exit 198
    }
    else if "`replace'" != "" {
      capture frame drop `pseudoframename'
    }
  }  
  
  c_local pseudoframename `pseudoframename'
  c_local pseudoframekeep `keep'
end

program define stpm3calplot_stats, rclass
  syntax [if] [in], [failure stat(string) pseudo(varname) pred(varname)]
  
  marksample touse
  
  tempvar po_event po_nonevent pevent
  qui gen `po_event'    = cond("`failure'"=="",1-`pseudo',`pseudo') if `touse'
  qui gen `po_nonevent' = 1 - `po_event' if `touse'
  qui  gen `pevent'     = cond("`failure'"=="",1-`pred',`pred') if `touse'  

  if "`stat'" == "brier" {
    tempvar Z
    qui gen `Z' = `pevent'^2 + `po_event' - 2*`pevent'*`po_event' if `touse'
    summ `Z' if `touse', meanonly
    c_local stat_`stat' `r(mean)'
  }
  if "`stat'" == "auc" {
    stpm3calplot_pseudo_AUC if `touse', po_event(`po_event')       ///
                                        po_nonevent(`po_nonevent') ///
                                        pevent(`pevent')
    c_local stat_`stat' `r(auc)'
  } 
  if "`stat'" == "calint" {
    tempvar cloglog_pevent
    qui gen `cloglog_pevent' = cloglog(`pevent')
    qui glm `po_event', link(cloglog) offset(`cloglog_pevent') vce(robust)
    c_local stat_`stat' `=_b[_cons]'
  }
  if "`stat'" == "calslope" {
    tempvar cloglog_pevent
    qui gen `cloglog_pevent' = cloglog(`pevent') 
    qui glm `po_event' `cloglog_pevent', link(cloglog) vce(robust)
    c_local stat_`stat' `=_b[`cloglog_pevent']'
  }  
end

program define stpm3calplot_pseudo_AUC, rclass sortpreserve 
  syntax [if] [in], po_event(varname) po_nonevent(varname) pevent(varname)
  marksample touse
  
  summ `po_event' if `touse', meanonly
  local po_event_sum `r(sum)'

  summ `po_nonevent' if `touse', meanonly
  local po_nonevent_sum `r(sum)'

  tempvar predid last pnonevent sum_po_event sum_po_nonevent FP TP
  egen `predid' = group(`pevent') if `touse'

  bysort `predid': gen `last' = _n==_N if `touse'
  
  gen `pnonevent' = 1 - `pevent'
  sort `pnonevent' `last'

  
  qui gen `sum_po_event'    = sum(`po_event')    if `touse'
  qui gen `sum_po_nonevent' = sum(`po_nonevent') if `touse'
  
  sort `pevent' `last'

  qui gen `TP' = `sum_po_event'   /`po_event_sum'    if `last'
  qui gen `FP' = `sum_po_nonevent'/`po_nonevent_sum' if `last'
  
  integ `TP' `FP' if `last'
  local integ = `r(integral)' 
  
  // add on point before to (0,0)
  summ `TP', meanonly
  local minTP `r(min)'
  summ `FP', meanonly
  local minFP `r(min)'
  qui local integ = `integ' + `minTP'*`minFP'*0.5
  return local auc `integ'
end

