*! version 0.03 2025-08-06
program define joinpoint_pred
  version 18.0
  syntax newvarlist(max=1) [if][in], [                            ///
                                      APC                         ///
                                      CI(namelist min=2 max=10)   /// 
                                      REGRESSPredict              ///
                                      EXPXB                       ///
                                      NKNOTS(numlist max=1)       ///
                                      STDP                        ///
                                      XB                          ///
                                      *                           ///
                                      ] 
  
  // check joinpoint model has been fitted
  marksample touse, novarlist

  // default is xb
  if "`xb'`expxb'`stdp'`apc'" == "" local xb xb
  
  // ci option checks
  if "`ci'" != "" {
    confirm new variable `ci'
    foreach opt in regresspredict stdp xb {
      if "``opt''" != "" {
        di as error "ci() option not compatable with `opt' option."
        exit 198
      }
    }
    local lcivar = word("`ci'",1)
    local ucivar = word("`ci'",2)
  }
  
  // run standard regress predict command
  if "`regresspredict'" != ""  {
    regres_p `varlist' `if'`in', `options'
    exit
  }
  
  
  if wordcount("`xb' `expxb' `stdp' `apc'") >1 {
    di as error "Only one of the xb, expxb, apc, and stdp options can be specified."
    exit 198
  }
 
  
  if "`nknots'" == "" {
    local nknots  `e(bestnknots)'
  }
  else if  subinword("`e(nknots)'","`nknots'","",1) == "`e(nknots)'" {
      di as error "A model with `nknots' was not fitted in joinpoint"
      exit 198
  }    
  
  
  // store current model
  tempname current_model
  estimates store `current_model'
  tempname original_splines
  tempvar id
  gen `id' = _n
  frame put `id' `e(linsplinenames)', into(`original_splines')    
  
  
  tempname predframe
  local yvar  `e(yvar)'
  local xvar  `e(xvar)'
  local hasse = "`e(sevar)" != ""
  local sevar `e(sevar)'
  
  tempvar tmpid
  gen `tmpid' = _n
  
  frame put `yvar' `xvar' `sevar' `touse' `tmpid' if e(sample), into(`predframe')
  
  frame `predframe' {
    if `hasse' local seopt se(`sevar')
    local knotsopt = cond(`nknots'==0,"nknots(0)","knots(`e(bestknots`nknots')')")
    joinpoint `yvar' `xvar', `seopt' `knotsopt'
    if "`xb'`expxb'" != "" {
      regres_p double xb if `touse', xb
      if "`ci'" != "" {
        qui regres_p double stdp if `touse', stdp
        
        local tval = invt(`e(df_r)',1-(1-c(level)/100)/2)
        gen double lci = xb - `tval' * stdp
        gen double uci = xb + `tval' * stdp
      }
      if "`expxb'" != "" {
        qui replace xb = exp(xb)
        if "`ci'" != "" {
          qui replace lci = exp(lci)
          qui replace uci = exp(uci)
        }
      }
    }
    else if "`stdp'" != "" {
      regres_p double xb if `touse', stdp
    }
    else if "`apc'" != "" {
      local Nintervals = `e(bestnknots)' + 1
      local zz _b[_ls1]
      forvalues i = 2/`Nintervals' {
        local zz `zz' + _b[_ls`i']*(_ls`i'>0)
      }
      gen xb = (exp(`zz') - 1)*100 if `touse'
    }
  }
  qui frlink 1:1 `tmpid', frame(`predframe')
  qui frget `varlist' = xb, from(`predframe')
  if "`ci'" != "" {
    qui frget `lcivar' = lci, from(`predframe')
    qui frget `ucivar' = uci, from(`predframe')
  }

// restore original model and spline variables  
  qui estimates restore `current_model'
  drop _ls*
  qui frlink 1:1 `id', frame(`original_splines')
  foreach v in `e(linsplinenames)' {
    local lslist `lslist' `v' = `v'
  }
  qui frget `lslist', from(`original_splines')
  
end

