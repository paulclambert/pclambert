// To do 
*! version 0.04 2025-09-07
program define joinpoint,  eclass
  version 18.0
  syntax anything(name=eq )                                     /// rate and xvar
                          [if][in]                              /// if and in
                          ,                                     ///
                          [                                     /// 
                          NKnots(numlist integer >=0 <=7 sort)  /// Number of knots (numlist)
                          APC                                   /// Display annual percentage change
                          APCv(string)                          /// APC options
                          BIC                                   /// select usig BIC (default)
                          BIC3                                  /// Select using BIC3
                          KNOTS(numlist)                        /// give specific knots
                          MININTPoints(integer 5)               /// miniumum values between knots   
                          MINENDPoints(integer 5)               /// miniumum values before first/last knot
                          SAVEMODELFIT                          /// save model fitting info
                          SE(varname)                           /// se on rate scale
                          VUNINFLATED                           /// Use uninflated V
                          VERBOSE                               /// verbose output
                          WBIC                                  /// weighted BIC
                          ]
  
  marksample touse
  
  di "This is a test version of joinpoint"
  
  // check moremata installed
  capture  findfile lmoremata.mlib
  if "`r(fn)'" == "" {
    di as error "You need to install moremata" 
    di as error "use" as {cmd: ssc install moremata}"
    exit 198
  }  
  
  if "`nknots'" == "" & "`knots'" == "" {
    di as error "Specify the number of knots (joinpoints) using the nknots() option."
    exit 198
  }
  if "`nknots'" != "" & "`knots'" != "" {
    di as error "You cannot specify both the nknots() and knots() options."
    exit 198
  }
  if "`bic'`bic3'`wbic'" == "" {
    local bic bic
  }
  if wordcount("`bic' `bic3' `wbic'")>1 {
    di as error "You have selected more than one model selection criterion."
    exit 198
  }
  
  // check and extract varlist
  if wordcount("`eq'") != 2 {
    di as error "varlist should consist of outcome variable and x variable."
    exit 198
  }
  local yvar    = word("`eq'",1)
  local xvar    = word("`eq'",2)
  confirm variable `yvar'
  confirm variable `xvar'
  local Number_Nknots = wordcount("`nknots'")
  
  qui replace `touse' = . if `touse' & (`xvar'==. | `yvar'==.)
  //check any missing standard errors
  
  
  // APC options
  if "`apcv'" !="" local apc apc
  if "`apc'" != ""  JP_get_APC_options, `apcv'
  
  // calculate weights
  if "`se'" != "" {
    tempvar wt
    qui gen double `wt' = 1/(`se'^2) if `touse'
    local addwt [aweight = `wt']
  }

  if "`se'" == "" {
    di as result "WARNING: The se() option is not specified (constant variance assumed)"
  }
  // Main program that does all the work
  mata: JP_fit_all_models()
  
  qui count if `touse' & !missing(`yvar',`xvar')
  local Nobs `r(N)'

  
  // find model with lowest BIC
  local BICtype = strupper("`bic'`bic3'`wbic'")
  local j 1
  if "`knots'" != "" local nknots = wordcount("`knots'")
  foreach m in `nknots' {
    local model_k`m'_df = `Nobs' - 2*(`m'+1)
    if `j'==1 local lowestBICm `m'
    else {
      if ``BICtype'_`m'' < ``BICtype'_`lowestBICm'' {
        local lowestBICm `m'
      }
    } 
    local ++j
  } 
  if `lowestBICm' == 0 local bestknots linear
  else local bestknots `bestknots`lowestBICm''

  // gen linear splines for "best" model
  capture drop _ls?
  JP_gen_lin_splines `xvar' if `touse', knots(`bestknots')
  local Nknots_best = wordcount("`bestknots'")
  
  // fit model
  qui count if `touse' & !missing(`yvar',`xvar')
  local model_df = `Nobs' - 2*(`Nknots_best'+1)
  tempname bestmodel V_uninflated
  qui regress `yvar' `linsplinenames' `addwt', dof(`model_df') 
  estimates store `bestmodel'
  if "`vuninflated'" == "" {
    matrix `V_uninflated' = e(V)

  
    // Inflate variance matrix
    if `lowestBICm' > 0 {
      JP_update_V `yvar', xvar(`xvar') knots(`bestknots')    ///
                             linsplinenames(`linsplinenames') df(`model_df') ///
                             addwt(`addwt')
      tempname Vupdate
      matrix `Vupdate' = r(V)
      qui estimates restore `bestmodel'
      ereturn repost V = `Vupdate'
    }
  }
  
  
  // print summary of models 
  di ""
  di as result "Summary of `totalmodels' models fitted"
  di as text " Knots {c |}" _col(10) "N models" _col(20) "Best knot choice" _col(55) "df" _col(65)"`BICtype'" 
  di as text "{hline 7}{c +}{hline 62}" 
  foreach m in `nknots' {
    local addstar = cond(`m' == `lowestBICm',"*","")
    di as text "  `m'" _col(8) "{c |}" as result _col(11) %6.0f `Nmodels`m'' ///
               _col(20) %~30s "`bestknots`m''" _col(55) `model_k`m'_df' _col(62) %6.2f ``BICtype'_`m'' "`addstar'"
  }
  di as text "{hline 7}{c +}{hline 62}" 
  di as result _col(9) "*: Model with lowest `BICtype'"

// Used in development  
//  di ""
//  di as result "Tempory BIC"
//  di as text " Knots {c |}" _col(10) "BIC" _col(25) "BIC3" _col(40) "R2wt" _col(55)"WBIC" 
//  di as text "{hline 7}{c +}{hline 62}"   
//  foreach m in `nknots' {
//    di as text "  `m'" _col(8) "{c |}" as result _col(11) %10.6f `BIC_`m'' ///
//               _col(26) %10.6f `BIC3_`m'' _col(41) %10.6f `R2wt_`m'' _col(56) %10.6f `WBIC_`m'' 
//  }    
//  di as text "{hline 7}{c +}{hline 62}" 
//  di ""
  
  // Show final model
  di ""
  di as result "Final Model with `lowestBICm' knots at " as text "(`bestknots')"
  regress, noheader 
  
  // Calculate and display APC
  if "`apc'" !="" {
    JP_calculate_APC `yvar' `xvar' if `touse',    ///
                  knots(`bestknots') weightvar(`wt') ///
                  nsamples(`Nsamples')               ///
                  `empirical'                        ///
                  linsplinenames(`linsplinenames')
    tempname apcmat
    matrix `apcmat' = r(apc)
    ereturn matrix apc =  `apcmat'
  }
 
 
 
// return list
  ereturn scalar bestnknots = `lowestBICm' 

  foreach m in `nknots' {
    ereturn local bestknots`m' `bestknots`m''
  }

  foreach m in `nknots' {
    ereturn local `BICtype'_`m' ``BICtype'_`m''
  }    
  
  if "`apc'" !="" {
    ereturn local APC
  }

  ereturn local nknots `nknots'
  ereturn local yvar   `yvar'
  ereturn local xvar   `xvar'
  if "`se'" != "" {
    ereturn local sevar `se'
  }
  ereturn local linsplinenames `linsplinenames'
  if "`vuninflated'" == "" {
  	ereturn matrix V_uninflated = `V_uninflated'
  }
  ereturn local predict joinpoint_pred
end  


*****************************
** extract APC options     **
*****************************
program define JP_get_APC_options
  syntax , [samples(integer 20000) empirical]
  c_local empirical `empirical'
  c_local Nsamples `samples'
end

*****************************
** generate linear splines **
*****************************
program define JP_gen_lin_splines,
  syntax varlist [if][in], knots(string) 
  marksample touse
  if "`knots'" == "linear" {
    gen _ls1 = `varlist' if `touse'
    local linsplinenames _ls1
  }
  else {
    mata: JP_gen_lin_splines_from_stata()
  }
  c_local linsplinenames `linsplinenames'
end

***********************************
** correction to variance matrix **
***********************************
program define JP_update_V, rclass
  syntax varname, [if][in] xvar(varname) knots(numlist) linsplinenames(varlist) df(string) [addwt(string)]
  marksample touse
  local Nknots = wordcount("`knots'")
  tempname xmin xmax prevknot
  summ `xvar' if `touse', meanonly
  scalar `xmin' = `r(min)'
  scalar `xmax' = `r(max)'
  
  local j 1
  scalar `prevknot' = `r(min)'
  foreach k in `knots' {
    tempvar int`j' slope`j'
    gen `int`j''    = (`xvar'>=`prevknot' & `xvar'<`k') if `touse'
    gen double `slope`j'' = `xvar'*(`xvar'>=`prevknot' & `xvar'<`k') if `touse'
	
	scalar `prevknot' = `k'
    local covlist `covlist' `int`j'' `slope`j''
	
	
  }
  tempvar intlast slopelast
  gen `intlast'    = (`xvar'>=`prevknot' & `xvar'<=`xmax') if `touse'
  gen double `slopelast' = `xvar'*(`xvar'>=`prevknot' & `xvar'<=`xmax') if `touse' 
  local covlist `covlist' `intlast' `slopelast'

  
  // exclude x values at knots 
  local knotscommas: subinstr local knots " " ",", all
  qui regress `varlist' `covlist' if `touse' &!inlist(`xvar',`knotscommas') `addwt',  nocons
  // transformation matrix
  tempname B
  matrix `B' = J(`Nknots'+2,(`Nknots'+1)*2,0)
  matrix `B'[1,1] = 1 
  local row = 2
  forvalues i=1/`=`Nknots'+1' {
     local j = `i'*2      
     matrix `B'[`row',`j'] = 1 
     local row = `row' + 1
     if `row'<=(`Nknots'+2) matrix `B'[`row',`j'] = -1 
  }
  
  
  tempname Vtmp
  mat `Vtmp' = `B'*e(V)*`B''
  
 
  local lastcol = `Nknots'+2
  mata: st_matrix(st_local("Vtmp"),st_matrix(st_local("Vtmp"))[(2..`lastcol',1),(2..`lastcol',1)])
  return matrix V `Vtmp'
end


*******************
** calculate APC **
*******************
program define JP_calculate_APC, rclass
  syntax varlist [if][in], knots(string) linsplinenames(varlist) ///
                           [EMPirical weightvar(string) nsamples(integer 1)] 
  marksample touse
  local yvar = word("`varlist'",1)
  local xvar = word("`varlist'",2)
  summ `xvar' if `touse', meanonly
  local xmin `r(min)'
  local xmax `r(max)'
  
  if "`knots'" != "linear" {
    local Nknots = wordcount("`knots'")
    local firstknot = word("`knots'",1)
    local interval1  "`xmin'-`firstknot'"
  }
  else {
    local Nknots 0
    local interval1  "`xmin'-`xmax'"
  }  
  local lnapc_xb _b[_ls1]
  qui lincom `lnapc_xb', eform 
  local apc1 = 100*(`r(estimate)' - 1)
  if "`empirical'" == "" {
    local apc1_lci = 100*(`r(lb)' - 1)
    local apc1_uci = 100*(`r(ub)' - 1)
  }

  forvalues k = 1/`Nknots' {
    local knot = word("`knots'",`k')
    local low  = `knot'+1
    local high = cond(`k'==`Nknots',             ///
                      "`xmax'",                  ///
                      word("`knots'",`k'+1))
    local intnum = `k' + 1                        
    local interval`intnum' "`low'-`high'"
      
    local lnapc_xb `lnapc_xb' + _b[_ls`intnum']
    qui lincom `lnapc_xb', eform 

    local apc`intnum' = 100*(`r(estimate)' - 1)
    if "`empirical'" == "" {
      local apc`intnum'_lci = 100*(`r(lb)' - 1)
      local apc`intnum'_uci = 100*(`r(ub)' - 1)      
    }
  }
  if "`empirical'" != "" {
    tempvar resid yhat
    qui predict double `yhat' if `touse', xb
    qui gen double `resid' = `yvar' - `yhat' if `touse'
    mata: JP_calculate_APC_empirical_CI()
  }
    
  local Nintervals = `Nknots' + 1
 
  di
  di as result "Annual percentage change (APC)"
  di as text "{hline 12}{c +}{hline 25}" 
  di as text "  Interval  {c |}" _col(25) "APC" 
  di as text "{hline 12}{c +}{hline 25}" 
    
  forvalues i = 1/`Nintervals' {
    di as text "  `interval`i'' " _col(13) "{c |}" _col(15) _continue 
    di as result %5.2f `apc`i'' " [" %5.2f `apc`i'_lci' "," %6.2f `apc`i'_uci' "]"
  }
  di as text "{hline 12}{c +}{hline 25}" 
  
  // matrix to return
  tempname apcmat
  matrix `apcmat' = J(`Nintervals', 3, .)
  forvalues i = 1/`Nintervals' {
    mat `apcmat'[`i',1] = `apc`i'' 
    mat `apcmat'[`i',2] = `apc`i'_lci'
    mat `apcmat'[`i',3] = `apc`i'_uci'
    local apcrownames `apcrownames' `interval`i''
  }
  matrix rownames `apcmat' = `apcrownames'
  matrix colnames `apcmat' = "APC" "APC_lci" "APC_uci"
  return matrix apc = `apcmat'
end

version 18.0
set matastrict on
mata:
/********************
 ** Fit all models **
 *******************/
void function JP_fit_all_models() {
  real         rowvector Nknots, Nmodels
  
  real         scalar    Nmodeltypes, minintpoints, minendpoints,
                         lowest_possible_knot, highest_possible_knot,
                         Nknots_m, i, m,s, N, verbose, w,
                         BICindexi, BIC3indexi, WBICindexi, bestindexi,
                         haswt, savemodelfit, calcBIC, calcBIC3, calcWBIC, RSS, R2max,
                         hasnknots
              
  string       scalar    touse, outcomename, xvarname,
                         orginalframe, newframe, wtname
                
  real         colvector outcome, xvar, bictmp, bic3tmp, wbictmp, R2wttmp, wt, justknots
  
  transmorphic matrix    knots, BIC, BIC3, WBIC, S, R2wt
  
  real         matrix    X
  
  string rowvector knot_varnames
  
 

  
  touse        = st_local("touse")
  verbose      = st_local("verbose") != ""
  haswt        = st_local("se") != ""
  hasnknots    = st_local("nknots") != ""
  savemodelfit = st_local("savemodelfit") != ""
  calcBIC     = st_local("bic") != ""
  calcBIC3     = st_local("bic3") != "" 
  calcWBIC     = st_local("wbic") != ""
  outcomename  = st_local("yvar")
  xvarname     = st_local("xvar")
  outcome      = st_data(.,outcomename,touse)
  xvar         = st_data(.,xvarname,touse)

  if(hasnknots) {
    Nknots = strtoreal(tokens(st_local("nknots")))
    Nmodeltypes = cols(Nknots)  
  }
  else {
    Nmodeltypes = 1
    
  }
  

  N = rows(outcome)
  if(haswt) {
    wtname = st_local("wt")
    wt = st_data(.,wtname,touse)
  }
  else wt = 1
  
  minintpoints   = strtoreal(st_local("minintpoints"))
  minendpoints   = strtoreal(st_local("minendpoints"))
  
  lowest_possible_knot  = min(xvar) + minendpoints
  highest_possible_knot = max(xvar) - minendpoints

  knots    = asarray_create("real",1)
  BIC      = asarray_create("real",1)
  BIC3     = asarray_create("real",1)
  WBIC     = asarray_create("real",1)
  R2wt     = asarray_create("real",1)
  Nmodels  = J(1,Nmodeltypes,.)
  // generate knots
  
  if(hasnknots) {
    if(verbose) display("Generating grid of knots")
    for(m=1;m<=Nmodeltypes;m++) {
      Nknots_m = Nknots[m]
      if(Nknots_m == 0) continue
     
      asarray(knots,m,JP_genknots_m(lowest_possible_knot,
                                    highest_possible_knot,
                                    Nknots_m,
                                    minintpoints))
      if(rows(asarray(knots,m))==0) {
        "Cannot create " + strofreal(Nknots_m) + " knots"
        exit(error(134))
      }                                  
    }
  }
  else {
    justknots = strtoreal(tokens(st_local("knots")))
    Nknots = cols(justknots)
    asarray(knots,1,justknots)
  }

// fit models
  if(verbose) display("Fitting models")
  for(m=1;m<=Nmodeltypes;m++) {
    Nknots_m = Nknots[m]
    if(verbose) display("  -- " + strofreal(Nknots_m) +" knot models")
    if(Nknots[m]>0) Nmodels[1,m] = rows(asarray(knots,m))
    else Nmodels[1,m] = 1 
    bictmp = J(Nmodels[1,m],1,.)
    if(calcBIC3 | calcWBIC) bic3tmp = J(Nmodels[1,m],1,.)
    if(calcWBIC) {
      wbictmp = J(Nmodels[1,m],1,.)
      R2wttmp = J(Nmodels[1,m],1,.)
    }
    for(i=1;i<=Nmodels[1,m];i++) {
      if(Nknots[m]>0) {
         X = JP_gen_lin_splines(xvar,asarray(knots,m)[i,])
      }
      else X = xvar
      S = mm_ls(outcome, X, wt)
// CHECK THIS
      if(haswt) RSS = mm_ls_rss(S) 
      else RSS = sum(wt:*((outcome - mm_ls_xb(S)):^2))

      bictmp[i] = ln(RSS:/N) :+ (2:*(Nknots_m :+ 1)):*ln(N):/N
      if(calcBIC3 | calcWBIC) bic3tmp[i] = ln(RSS:/N) :+ (3:*(Nknots_m) + 2 ):*ln(N):/N
    
      if(calcWBIC) {
        if(Nknots[m]==0) {
          wbictmp[i] = bictmp[i]
          continue
        }
        R2max = JP_calc_R2max(outcome,X,asarray(knots,m)[i,],S,wt)
        wbictmp[i] = (1-R2max)*bictmp[i] + R2max*bic3tmp[i]
        R2wttmp[i] = R2max
      }
    }
    asarray(knots,Nknots_m,asarray(knots,m))  
    asarray(BIC,Nknots_m,bictmp)
    if(calcBIC3 | calcWBIC) asarray(BIC3,Nknots_m,bic3tmp)
    if(calcWBIC) {
      asarray(WBIC,Nknots_m,wbictmp)
      asarray(R2wt,Nknots_m,R2wttmp)
    }

    


    minindex(asarray(BIC,Nknots_m),1,BICindexi=.,w=.)
    if(calcBIC3 | calcWBIC) minindex(asarray(BIC3,Nknots_m),1,BIC3indexi=.,w=.)
    if(calcWBIC) minindex(asarray(WBIC,Nknots_m),1,WBICindexi=.,w=.)
    
    st_local("BIC_"+strofreal(Nknots[m]),strofreal(asarray(BIC,Nknots_m)[BICindexi,]))

    if(calcBIC3) {
      st_local("BIC3_"+strofreal(Nknots[m]),strofreal(asarray(BIC3,Nknots_m)[BIC3indexi,]))
      bestindexi = BIC3indexi
    }
    else if(calcWBIC) {
      st_local("BIC3_"+strofreal(Nknots[m]),strofreal(asarray(BIC3,Nknots_m)[WBICindexi,]))
      st_local("WBIC_"+strofreal(Nknots[m]),strofreal(asarray(WBIC,Nknots_m)[WBICindexi,]))
      st_local("R2wt_"+strofreal(Nknots[m]),strofreal(asarray(R2wt,Nknots_m)[WBICindexi,]))
      bestindexi = WBICindexi
    }
    else bestindexi = BICindexi

    if(Nknots[m]>0) {
      st_local("bestknots"+strofreal(Nknots[m]),
               invtokens(strofreal(asarray(knots,Nknots_m)[bestindexi,])))
    }    
  

    st_local("Nmodels"+strofreal(Nknots[m]),strofreal(Nmodels[m]))
    
    knot_varnames = J(1,0,"")
    for(s=1;s<=Nknots_m;s++) {
      knot_varnames = knot_varnames, "knot" + strofreal(s)
    }
    
    // save model fit
    // currently error if frame exists
    if(savemodelfit) {
      orginalframe = st_framecurrent()
     
      // change to tempory when working only have as an option
      if(Nknots[m]==0) continue 
      newframe = "_knots"+strofreal(Nknots[m])
      (void) _st_framedrop(newframe,0)
      st_framecreate(newframe)
      st_framecurrent(newframe)
      st_addobs(rows(asarray(knots,m)))
  
      (void) st_addvar("int",knot_varnames)
      st_store(.,knot_varnames,asarray(knots,m))
      (void) st_addvar("double",("BIC"))
      st_store(.,("BIC"),(asarray(BIC,Nknots_m)))
      if(calcBIC3 | calcWBIC) {
        (void) st_addvar("double",("BIC3"))
        st_store(.,("BIC3"),(asarray(BIC3,Nknots_m)))        
      }
      if(calcWBIC) {
        (void) st_addvar("double",("R2wt"))
        st_store(.,("R2wt"),(asarray(R2wt,Nknots_m)))         
        (void) st_addvar("double",("WBIC"))
        st_store(.,("WBIC"),(asarray(WBIC,Nknots_m)))      
      }  
      st_framecurrent(orginalframe)
    }
  }
  st_local("totalmodels",strofreal(sum(Nmodels)))
  
}


/*****************************
 ** generate linear splines **
 ****************************/
real matrix JP_gen_lin_splines(real colvector x, real rowvector knots) {
  real scalar Nknots, Nx
  real matrix X, knotsexpand
  
  Nknots = cols(knots)
  Nx = rows(x)
  X = J(Nx,Nknots + 1,.)
  X[,1] = x 

  knotsexpand = J(Nx,1,knots)
  X[,2..(Nknots + 1)] = (x :- knotsexpand) :*((x :- knotsexpand):>0)
  return(X)  
}

void function JP_gen_lin_splines_from_stata()
{
  string scalar touse
  real colvector x
  real rowvector knots
  real matrix X
  string colvector linsplinenames
  real scalar i
  
  touse = st_local("touse")
  x = st_data(.,st_local("varlist"),touse)
  knots = strtoreal(tokens(st_local("knots")))
  X = JP_gen_lin_splines(x,knots)
  linsplinenames = J(1,0,"")
  for(i=1;i<=(cols(knots)+1);i++) {
    linsplinenames = linsplinenames, "_ls" + strofreal(i)
  }
  (void) st_addvar("double",linsplinenames)
  st_store(.,linsplinenames,touse,X)
  st_local("linsplinenames",invtokens(linsplinenames))
}


/*********************************
 ** generate all possible knots **
 ********************************/
real matrix JP_genknots_m(real scalar xmin, 
                          real scalar xmax, 
                          real scalar Nknots, 
                          real scalar M) 
{
    real scalar required_span, T, i
    real matrix Y, base, K

    if (xmax < xmin) return(J(0, Nknots, .))

    required_span = (Nknots - 1) * (M + 1)
    if((xmax - xmin) < required_span) return(J(0, Nknots, .))

    T = xmax - xmin - required_span
    if(T < 0) return(J(0, Nknots, .))

    Y = JP_generate_y_le(Nknots, T)

    if(!rows(Y)) return(J(0, Nknots, .))

    base = xmin :+ (0..(Nknots - 1)) :* (M + 1)
    K = J(rows(Y), Nknots, .)

    for(i = 1; i <= rows(Y); i++) {
      K[i, .] = base :+ runningsum(Y[i, .])
    }

    return(K)
}

real matrix JP_generate_y_le(real scalar n, 
                             real scalar t_max)
{
  real matrix res, sub_res
  real scalar y
    
  if(n==1) {
    return((0::t_max))
  }
  else {
    res = J(0, n, .)
    for(y = 0; y <= t_max; y++) {
      sub_res = JP_generate_y_le(n - 1, t_max - y)
      if (rows(sub_res)) {
        res = res \ (y * J(rows(sub_res), 1, 1), sub_res)
      }
    }
    return(res)
  }
}


/********************************
 ** calculate APC empirical CI **
 *******************************/
 // see https://onlinelibrary.wiley.com/doi/epdf/10.1002/sim.9407
void JP_calculate_APC_empirical_CI()
{
  real colvector resid, yhat, z, eta_b, wt, U1, U2, y_b, residorder
  real rowvector knots
  real matrix X, betas, slopes, lci, uci
  string scalar touse
  real scalar Nsamples, i, k, j, N, Nsplines
  transmorphic matrix S
  real matrix Xint
  
  touse = st_local("touse")
  Nsamples = strtoreal(st_local("nsamples"))
  resid = st_data(.,st_local("resid"),touse)
  yhat  = st_data(.,st_local("yhat"),touse)
  residorder = order(resid,1)
  resid = resid[residorder]
  yhat  = yhat[residorder]
  X = st_data(.,st_local("linsplinenames"),touse)[residorder,]
  N = rows(resid)  
  Nsplines = cols(X)

  knots = strtoreal(tokens(st_local("knots")))
  
  if(st_local("weightvar")!="") {
    wt = st_data(.,st_local("weightvar"),touse)[residorder,]
  }
  else wt = 1

  // add intercepts to X
  Xint =  J(N,0,.)
  for(k=1;k<=(Nsplines-1);k++) {
    Xint = Xint , (X[,1]:>= knots[k])
  }
  X = X,Xint
  z = JP_eta_add_ends(resid)

  // Fit Nsample models
  betas = J(Nsamples,Nsplines,.)
  for(j=1;j<=Nsamples;j++) {
    U1 = runiform(N,1,0,1)
    U2 = ceil(U1:*(N+1))

    eta_b = z[U2] :+ (z[U2:+1] :- z[U2]):*((U1 :- (U2:-1):/(N+1)):*(N+1))
    //eta_b = z[U2] :+ (z[U2:+1] :- z[U2]):*runiform(N,1,0,1) 
    y_b = yhat :+ eta_b
    
    S = mm_ls(y_b, X, wt,1)
    betas[j,] =  mm_ls_b(S)'[1..Nsplines] 
  }
  //get APC
  slopes = betas[,1]
  for(i=2;i<=Nsplines;i++) {
    slopes = slopes , (slopes[,i-1] :+ betas[,i])
  }
  
  //slopes = betas
  lci = 100:*(exp(mm_quantile(slopes,1,0.025)) :-1)
  uci = 100:*(exp(mm_quantile(slopes,1,0.975)) :-1)

  // save to locals
  for(i=1;i<=(Nsplines);i++) {
    st_local("apc"+strofreal(i)+"_lci",strofreal(lci[i]))
    st_local("apc"+strofreal(i)+"_uci",strofreal(uci[i]))
  }
}

real colvector JP_eta_add_ends(resid){
  real scalar IQR, D, N, Q1, Q3, z0, znp1

  N = rows(resid)  
  Q1 = mm_quantile(resid,1,0.25,2)
  Q3 = mm_quantile(resid,1,0.75,2)
  IQR = Q3 - Q1
  D = 1.5*IQR 
  z0   = (resid[1]:<= (Q1 - D)) ? (resid[1]:-2:*IQR:/N) : Q1-D
  znp1 = (resid[N]:>= (Q3 + D)) ? (resid[N]:+2:*IQR:/N) : Q3+D
  return(z0\resid\znp1)
}


/********************
 ** calculate WBIC **
 *******************/
function JP_calc_R2max(
                       real         matrix    Y,
                       real         matrix    X,
                       real         rowvector knots,
                       transmorphic matrix    S,
                       real         colvector wt
                      ) 
{
  real scalar    s, Nknots, Nall
  real matrix    X2, X0, X0tmp, H0, IH0
  real colvector selectX0, z, R2i, beta, sqrt_wt, Ytmp
  real rowvector xminmax, YIH0
  
  beta =  mm_ls_b(S)
  Nknots = cols(knots)

  R2i = J(1,Nknots,.)
  Nall = rows(X) 

  xminmax = minmax(X[,1]) // could be in structure
  
  sqrt_wt = sqrt(wt)
  if(rows(sqrt_wt)==1) sqrt_wt=J(rows(X),1,1)

  knots = xminmax[1]-1,knots,xminmax[2]

  X0 = (X[,1],J(rows(X),1,1)):*sqrt_wt
  for(s=1;s<=Nknots;s++) {
    selectX0 = selectindex(X[,1]:>knots[s] :& X[,1]:<=knots[s+2])
    X0tmp = X0[selectX0,]
    Ytmp =  Y[selectX0,]:*sqrt_wt[selectX0,]
    H0 = X0tmp*invsym(cross(X0tmp,X0tmp))*X0tmp'
    z = X[selectX0,s+1]:*sqrt_wt[selectX0,]
    IH0 = I(rows(H0)):-H0
    YIH0 = Ytmp'*(IH0)
    R2i[s] = (YIH0*z)^2/((YIH0*Ytmp)*(z'*(IH0)*z))
  }

  return(max(R2i))
}


end

