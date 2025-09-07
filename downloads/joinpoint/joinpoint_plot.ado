// default: plot best model
// choose model of those selected
// show APC + choose pos

program define joinpoint_plot
  syntax [if][in], [nknots(string) ci log apc apcpos(integer 5)  ///
            title(string) name(string)                   ///
            *                                            ///
           ]
  
  marksample touse
  
  local otheroptions `options'
  
  // extract allowed graph options
  _get_gropts, graphopts(`otheroptions') getallowed(xtitle ytitle title xline yline xscale yscale text ylabel xlabel)
  if "`s(graphopts)'" ! = "" {
    di as error `"Illegal option(s), `s(graphopts)'"'
    exit 198
  }
  if `"`s(ytitle)'"' == "" local ytitle ytitle("Rate")
  if `"`s(xtitle)'"' == "" local xtitle xtitle("Year")
  if `"`s(legend)'"' !=""  local haslegend haslegend
  
  tempname current_model
  qui estimates store `current_model'
  tempname original_splines
  tempvar id
  gen `id' = _n
  frame put `id' `e(linsplinenames)', into(`original_splines')    

  if "`nknots'" != "" {
    confirm integer number `nknots'
    local enknots `e(nknots)'
    local enknotscommas: subinstr local enknots " " ",", all
    if !inlist(`nknots', `enknotscommas') {
      di as errod "model with `nknots' not fitted"
    }

    
    // apc options should be consistent
    local knotsopt = cond(`nknots'==0,"nknots(0)","knots(`e(bestknots`nknots')')")
    joinpoint `e(yvar)' `e(xvar)' if e(sample) & `touse', `knotsopt' apc
    
  }
  
  // check joinpoint model
  
  // check knots compatable
  tempvar xb xb_lci xb_uci rate
  qui predictnl `xb' = xb() if e(sample) & `touse', ci(`xb_lci' `xb_uci') 
  qui replace `xb'     = exp(`xb')     if e(sample) & `touse'
  qui replace `xb_lci' = exp(`xb_lci') if e(sample) & `touse'
  qui replace `xb_uci' = exp(`xb_uci') if e(sample) & `touse'
  
  if "`ci'" != "" {
    local rarea (rarea `xb_lci' `xb_uci' `e(xvar)' if e(sample) & `touse', pstyle(p2line) color(%30))
  }
  
  if "`log'" != "" {
    local yscale yscale(log)
  }
  qui gen double `rate' = exp(`e(yvar)')  if e(sample) & `touse'
  
  
  // APCs
  if "`apc'" != "" {
    tempname apc
    matrix `apc' = e(apc)
    local Nintervals = `e(bestnknots)' + 1
    local interval_names: rownames `apc'
    local apctext "APC       "
    forvalues i = 1/`Nintervals' {
      local inti = word("`interval_names'",`i')
      local apcval: display %5.2f `apc'[`i',1]
      local apclci: display %6.2f `apc'[`i',2]
      local apcuci: display %6.2f `apc'[`i',3]
            
      local apctxt: display  "{stMono: `inti': `apcval' [`apclci',`apcuci']}"
      local apctext `"`apctext' "`apctxt'""'
    
      local apctextopt note(`apctext', ring(0) pos(`apcpos') box justification(center) linegap(*1.2))
    }
  }
  // restore model and linear splines
  qui estimates restore `current_model'
  drop _ls*
  qui frlink 1:1 `id', frame(`original_splines')
  foreach v in `e(linsplinenames)' {
    local lslist `lslist' `v' = `v'
  }
  qui frget `lslist', from(`original_splines')

  
  twoway (scatter `rate' `e(xvar)' if e(sample) & `touse') ///
         (line `xb' `e(xvar)' if e(sample) & `touse', sort)             ///
         `rarea',                                ///
         `ytitle'                                ///
         `xtitle'                                ///
         `otheroptions'                          ///
         `apctextopt'                            ///
         title(`"`title'"')                      ///
         name(`name')                            ///
         legend(off) `yscale'
  
end



