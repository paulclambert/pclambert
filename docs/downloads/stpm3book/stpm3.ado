*! version 1.11 2024-06-12

program stpm3, eclass byable(onecall)
	version 16.1

  local optcopy `0'
  syntax [anything] [if] [in] , [*]
  if replay() {
    syntax [,df(string) knots(string) allknots(string)  *]
    if "`df'`knots'`allknots'" != "" Estimate `0'
    else {
      if ("`e(cmd)'"!= "stpm3") error 301
      Replay `optcopy'
      exit
    }
  }
  else Estimate `optcopy'
  ereturn local cmd "stpm3"
	ereturn local cmdline `cmd' `optcopy'
end

program Estimate, eclass 
	st_is 2 analysis	
  syntax [anything] [fw pw iw aw] [if] [in],     ///
         [                                       ///
         ALLKNots(passthru)                      /// allknots
         ALLKNOTSTvc(passthru)                   /// allknots tvc
         BHAZard(varname numeric)                /// bhazard for RS models
         BKNOTs(passthru)                        /// bknots
         BKNOTSTVC(passthru)                     /// bknotstvc
         INTEGOPTions(string)                    /// integoptions
         DEGree(integer 3)                       /// degree for BS splines
         DF(passthru)                            /// df for basleine
         DFTVC(passthru)                         /// df for tvc
         EFORM                                   ///
         FROM(string)                            ///
         INITModel(string)                       ///
         INITVALUESLOOP                          ///
         KNOTs(passthru)                         /// internal knots
         KNOTSTVC(passthru)                      /// 
         MLADOPTions(string)                     ///
         MLMETHOD(string)                        ///
         NEQ(integer 2)                          ///
         noCONStant                              ///
         NODEs(integer 30)                       ///
         OFFset(varname numeric)                 ///
         PYthon                                  ///
         SCale(string)                           ///
         SPLINEType(string)                      ///
         TTRans(string)                          ///
         TVC(string asis)                        ///   
         TVCOFFset(string)                       /// not yet implemented
         VCE(string)                             ///
         VERBOSE                                 ///
                *                                /// -mlopts- options
         ]

  local cmdline `"stpm3 `0'"'         

// error checks         
  if "`df'`knots'`allknots'" == "" {
    di as error "You must specify one of the df(), knots() or allknots() options."
    exit 198
  }       
  if (("`df'"!="") +  ("`knots'" != "") + ("`allknots'" != ""))>1 {
    di as error "You can only specify one of the the df(), knots() and allknots() options."
    exit 198
  }
  if "`dftvc'" != "" & "`knotstvc'" != ""  {
    di as error "You can only specify one of the the dftvc() and knotstvc() options."
    exit 198
  }
  if "`tvc'" != "" & ("`dftvc'" == "" & "`knotstvc'" == "" & "`allknotstvc'" == "") {
    di as error "You must specify either the dftvc(), knotstvc() or allknotstvc() options with the tvc() option."
    exit 198
  }
  if "`tvc'" == "" {
    if "`dftvc'" != "" | "`knotstvc'" != "" | "`allknotstvc'" != "" {
      di as error "You must specify the tvc option if using the dftvc(), knotstvc() or allknotstvc() options."
      exit 198
    }
    if "`tvcoffset'" != "" {
      di as error "The tvcoffset option is not currently implemented."
	  exit 198
    }
  }
 
  if "`splinetype'" == "" local splinetype ns
  if !inlist("`splinetype'","ns","bs","rcs","ms") {
    di as error "Only ns, bs or rcs splines currently implemented."
  }

  if "`python'" != "" {
    capture  which  mlad
    if  _rc  >0  {
      display as  error "You need to install the  -mlad- command to the the python option." ///
                           "This can  be  installed  using,"
      display in error  ".  {stata ssc install mlad}"
      exit    198
    }
    if "`scale'" != "lnhazard" {
      di as error "The python option can only be used with scale(lnhazard) models."
      exit 198
    }
  }  
  
 
  
// drop spline vars etc if previous model fitted 
  capture drop _ns*
  capture drop _fp*
  capture drop _dns*     
  capture drop _bs*
  capture drop _rcs*
  capture drop _drcs*
  capture drop _dbs*
  capture drop _poly*  
  capture drop _fn*
  
  // scale
  getscaleoption, `scale'

// marksample, total obs and indicator for delayed entry
  marksample touse
	qui replace `touse' = 0  if _st==0 | `touse' == . | _st==.  
  
// log or transformed time  
  if "`ttrans'" == "" local ttrans lnt
  
  if "`integoptions'" != "" {
    if "`scale'" != "lnhazard" {
      di as error "Only set integoptions() for lnhazard models"
      exit 198
    }
  }
  if "`scale'" == "lnhazard" parse_integ_options, `integoptions' ttrans(`ttrans')

// extended functions varlist
  local varlist_original `anything'  
  local tvc_orignal `tvc'

  stpm3_extract_extfunction `anything' 

  local anything `r(cleanedvarlist)'
  local extfunclist `"`r(extfunclist)'"'
  
  
  if "`tvc'" != "" {
    stpm3_extract_extfunction `tvc', tvc 
    local extfunclist `"`extfunclist' `r(extfunclist)'"'
    local tvc `r(cleanedvarlist)'
  }
  stpm3_gen_extended_functions `extfunclist', xb("`anything'") tvc("`tvc'") 
  
  if `"`tvc'"' != "" local tvcopt tvc(`tvc')  
  
  // add to touse (for missing covariates)
  markout `touse' `model_vars' 
  
  qui count if `touse'
  local Nobs `r(N)'
	if `r(N)' == 0 {
    display in red "No observations"
    exit 2000
  }
  
  qui count if `touse' & _d
  if `r(N)' == 0 {
    display in red "No failures"
    exit 198
  }  
  
	summ _t0 if `touse' , meanonly
  local hasdelentry = cond(`r(max)'>0,1,0)
  if `hasdelentry' {
    tempvar touse_t0 
    qui gen byte `touse_t0' = `touse'*(_t0>0)
  }
  if "`constant'"=="" {
    tempvar cons 
    qui gen byte `cons'  = 1 if `touse' // Needed for st_view
  }
// bhazard  
  if "`bhazard'" != "" {
    qui count if missing(`bhazard') & `touse'
    if `r(N)' {
      di as err "background hazard contains missing values"
      exit
    }
  }
  // knots options
  if "`knots'" != "" & "`allknots'" != "" {
    di as error "Only one of knots() and allknots() options can be used"
    exit 198
  }
  
  if "`allknots'" != "" & "`bknots'" != "" {
    di as error "You can't use the bknots() and allknots() options in combination"
    di as error "Use knots() to specify internal knots"
    exit 198
  }
  if "`knotstvc'" != "" & "`allknotstvc'" != "" {
    di as error "Only one of knotstvc() and allknotstvc() options can be used"
    exit 198
  }
  
  if "`allknotstvc'" != "" & "`bknotstvc'" != "" {
    di as error "You can't use the bknotstvc() and allknotstvc() options in combination"
    di as error "Use knotstvc() to specify internal knots"
    exit 198
  }  
    
// ml options
  _get_diopts diopts options, `options'   
  mlopts mlopts, `options'    

  if "`offset'" != "" {
  	di as error "Offset option not currently implemented."
    exit 198
  }

  if "`s(constraints)'" != "" local constraints constraints(`s(constraints)')


// Weights 
  local wt: char _dta[st_w]       
  local wtvar: char _dta[st_wv]
  
// Generate time spline variables
  if "`verbose'" != "" di "Generating Splines"

  stpm3_gensplines  if `touse', `df' `knots' `tvcopt' `dftvc' `knotstvc'        /// 
                                `allknots' `bknots' `allknotstvc' `bknotstvc'    ///
                                type(`splinetype') hasdelentry(`hasdelentry')   ///
                                ttrans(`ttrans') degree(`degree')               ///
                                subcentile(_d==1) scale(`scale') wtvar(`wtvar')

  if "`scale'" == "lnhazard" & `df'==1 {
    di as error "Minimum df for lnhazard models is 2"
    exit 198
  }                                
                                
// initial values
  if "`from'" == "" {
    if "`verbose'" != "" di "Obtaining Initial Values"
    tempname initbeta
    if "`initmodel'" == "" local initmodel = cond("`scale'"!="lnhazard","cox","cox")
    CoxInit `varlist' if `touse', scale(`scale') splinevars(`splinelist') ///
                                  splinetvcvars(`splinelist_tvc')         ///
                                  `constant'                              ///
                                  bhazard(`bhazard')                      ///
                                  hasdelentry(`hasdelentry')              ///
                                  model(`initmodel')
    matrix `initbeta' = r(initmat)
    
    
    local initopt init(`initbeta',copy)
  }
  else {
    tempname b0
   _mkvec `b0', from(`from') error("from()")
   local initopt "init(`b0',`s(copy)' `s(skip)')"   
  }

  
// store columns for tvc  
  fvexpand `varlist'
  local start = wordcount("`r(varlist)'") + 1
  local end = colsof(e(b))

  tempname splinebeta
  matrix `splinebeta' = e(b)[1,`start'..`end']

  if "`tvc'" != "" {
    if `sharedtvc_knots' {
      local j 1
      foreach v in `tvc_included' {
        foreach tv in `splinevars_tvc' {
          local tvccol`j' `tvccol`j'' `=colnumb(`splinebeta',"`v'#c.`tv'")'
        }
        local ++j
      }
    }
    else {
      local j 1
      foreach v in `tvc_included' {
        _ms_parse_parts `v'
        local tvc_nofactor `tvc_nofactor' `r(name)'
        foreach tv in `splinevars_tvc_`r(name)'' {
          local tvccol`j' `tvccol`j'' `=colnumb(`splinebeta',"`v'#c.`tv'")'
        }
        local ++j
      }
    }
  }

// For integration up to first knot and after last knot  
  if "`allnum'" == "" & inlist("`splinetype'","ns","rcs") & "`scale'" == "lnhazard" {
    
    // ERROR IF BSPLINES
    // NEED TO ADD RCS
    
    
    tempvar P1_lower P1_upper P2_lower P2_upper
    tempvar P3_lower P3_upper
    tempvar includefirstint includesecondint includethirdint
   
    
    local minknot = word("`bknots'",1)
    local maxknot = word("`bknots'",2)
    if "`ttrans'" == "lnt" {
      local minknot = exp(`minknot')
      local maxknot = exp(`maxknot')
    }
    
    
    // NEED TO ADD WHERE MINIMUM IS WITH TVCs
    
    qui gen double `P1_upper' = cond(_t>=`minknot',`minknot',_t)         if `touse'
    qui gen double `P1_lower' = _t0                                      if `touse'
    qui gen double `P2_lower' = cond(_t0>`P1_upper',_t0,`P1_upper')      if `touse'
    qui gen double `P2_upper' = cond(_t>=`maxknot',`maxknot',_t)         if `touse'
    qui gen double `P3_lower' = cond(_t0<`maxknot',`maxknot',_t0)        if `touse'
    qui gen double `P3_upper' = _t                                       if `touse'
    qui gen byte   `includefirstint'  = _t0<`P1_upper'                   if `touse'
    qui gen byte   `includesecondint' = (_t0<`maxknot') & (_t>`minknot') if `touse'
    qui gen byte   `includethirdint'  = _t>`P3_lower'                    if `touse'  
  }
  
// need to add `offopt'  & call bhazard etc.
  if "`offset'" != ""  local offopt "offset(`offset')"
  if "`varlist'" != "" local xb (xb: =  `varlist', nocons `offopt')
  local empty_varlist = "`varlist'"==""

// maximize likelihood in Stata  
  if "`python'" == "" {
// Set up structure in Mata
    if "`verbose'" != "" di "Setting up Mata Structure"
    local alldsplinevars `dsplinelist' `dsplinelist_tvc'
    local delentryvars   `delentryvars' `=cond("`constant'"=="","`cons'","")'
    local rs = cond("`bhazard'"!="" & "`scale'" != "lnhazard","_rs","")

    if "`allnum'" != "" local allnum _allnum
    local Nsplinevars = wordcount("`splinelist' `splinelist_tvc'")

    tempname stpm3_struct
    mata: stpm3_setup("`stpm3_struct'")
    local userinfo userinfo(`stpm3_struct')     	
	
    if "`initvaluesloop'" != "" {
      local captureml capture
      local initvalmodels exp weibull stpm2
    }
    if "`scale'" == "probit" & "`mlmethod'" == "" {
      local mlmethod = cond("`bhazard'"=="","gf1","gf0")
    }
    if "`scale'" == "lnodds" & "`mlmethod'" == "" {
      local mlmethod = cond("`bhazard'"=="","gf2","gf0")
    }  
    
    if "`mlmethod'" == "" local mlmethod gf2    
    if "`vce'" != "" local vce vce(`vce')
    
    `captureml' ml model `mlmethod' stpm3_gf2_`scale'`rs'`allnum'()         /// 			
	  			               `xb'                                               ///
                         (time: = `splinelist'                              ///
                                  `splinelist_tvc',                         ///
                                  `constant' )                              ///
	  			               if `touse'                                         ///
	  			               `wt',                                              ///
	  			               `mlopts'                                           ///
                         `vce'                                              ///
                         `constraints'                                      ///
                         `offopt'                                           ///
                         userinfo(`stpm3_struct')                           ///
	  			               search(off)                                        ///
                         `initopt'                                          ///
	  			               maximize  
    
    if ((c(rc) == 1400) | !`e(converged)') & "`initvaluesloop'" != "" {
      capture mata: rmexternal("`stpm3_struct'")    
      forvalues m=1/3 {
        local initmodname = word("`initvalmodels'",`m')
        noi di as txt "[initial values infeasible, retrying with -initmod(`initmodname')- option]"
        capture `cmdline' initmod(`initmodname')
        capture mata: rmexternal("`stpm3_struct'")
        if "`e(converged)'"=="1" {
          Replay, `eform' `diopts' `header'   
          continue, break
        }
        if `m' == 3 {
          di "Model not converged"
          exit 198
        }
        local ++m
      }    
    }

    
  }
  else {
// maximize likelihood in Python    
    tempname Nnodes Ntvc hasbhazard ttrans_log hasvarlist hasconstant
    tempname spline_bs spline_ns spline_rcs bs_degree pyallnumint
    tempname hastanhsinh pytanhsinh_N 
    
    scalar `Nnodes' = `nodes'
    scalar `ttrans_log' = "`ttrans'" == "lnt"
    qui count if `touse'
    scalar `Ntvc' = wordcount("`tvc_included'")
    scalar `hasbhazard' = "`bhazard'" != ""
    scalar `hasvarlist'    = "`varlist'" != ""
    
    scalar `spline_bs'  = "`splinetype'" == "bs"
    scalar `spline_ns'  = "`splinetype'" == "ns"
    scalar `spline_rcs' = "`splinetype'" == "rcs"
    scalar `bs_degree'  =  `degree'
    scalar `hasconstant' = "`constant'" == ""
    scalar `pyallnumint' = "`allnum'" != ""
   
    scalar `hastanhsinh' = "`tanhsinh'" != ""
    if !`hastanhsinh' local tanhsinh_N 0
    scalar `pytanhsinh_N'  = `tanhsinh_N'
    
    
    local scalarlist `spline_bs' `spline_ns' `spline_rcs' `bs_degree' ///
                     `hasbhazard' `Nnodes' `ttrans_log' `Ntvc' `pyallnumint' ///
                     `hastanhsinh' `pytanhsinh_N' 
    local scalarnames spline_bs spline_ns spline_rcs bs_degree ///
                      hasbhazard Nnodes ttrans_log Ntvc pyallnumint ///
                      hastanhsinh tanhsinh_N 
    local staticscalars `hasvarlist' `hasconstant' `ttrans_log'                 
        
    tempname knots_matrix
    mata: st_matrix(st_local("knots_matrix"),strtoreal(tokens(st_local("knots"))))
    local matlist `knots_matrix'
    local matnames_list knots
 
 // add tvc stuff here (this is from strcs2)
    local j 1
    foreach tvcvar in `tvc_included' {
      tempname knotstvc_mat`j'
      if `sharedtvc_knots' {
        mata: st_matrix(st_local("knotstvc_mat`j'"),strtoreal(tokens(st_local("knots_tvc"))))
      }
      else {
        mata: st_matrix(st_local("knotstvc_mat`j'"),strtoreal(tokens(st_local("knots_tvc_`tvcvar'"))))
      }
      local matlist `matlist' `knotstvc_mat`j''
      local matnames_list `matnames_list' tvcknots`j'
      local tvcnames `tvcnames' tvc`j'
      fvrevar `tvcvar'
      local tvctemplist `tvctemplist' `r(varlist)'
      local j = `j' + 1
    }
    
    // zeros used for non bhazard models
    tempvar zeros
    gen `zeros' =  0    
    local othervn_list t0 t d bh
    if "`bhazard'" == "" {
      local bhazard `zeros'
    }
    local othervn_list `othervn_list' `tvcnames'   
    local othervarslist _t0 _t _d `bhazard' `tvctemplist'  
    
    if "`allnum'" == "" {
      local othervarslist `othervarslist' `P1_lower' `P1_upper'       ///
                          `P2_lower' `P2_upper' `P3_lower' `P3_upper' ///
                          `includefirstint' `includesecondint' `includethirdint'
      local othervn_list `othervn_list' P1_lower P1_upper    ///
                         P2_lower P2_upper P3_lower P3_upper ///
                         includefirstint includesecondint includethirdint
    }
    
   
    // robust standard errors (should be able to add this??)
    if "`vce'" != "" {
      _vce_parse , optlist(Robust) argoptlist(CLuster) : , vce(`vce')
      local hasrobust = "`r(robust)'" != ""
      local hasid     = "`r(cluster)'" != ""
      if `hasid' local idopt id(`r(cluster)')
      if `hasrobust' local robustopt robustok scoretype(direct)
    }

    if "`mlmethod'" != "" {
      local mlmethodopt mlmethod(`mlmethod')
      
    }
    
    // mlad program
    local mlad_program = cond("`allnum'"=="","stpm3_hazard_3parts","stpm3_hazard_numint") 
    
    // need to store tvcname in global so mlad has access
    global stpm3_mlad_time_varlist `splinelist' `splinelist_tvc'
 
    mlad `xb'                                          ///
         (time: = `splinelist'                         ///
                  `splinelist_tvc',                    ///
                  `constant' )                         ///
         if  `touse'                                   ///
         `wt',                                         ///
         llfile(`mlad_program')                        ///
         pysetup(stpm3_hazard_setup)                   ///
         othervars(`othervarslist')                    ///
         othervarnames(`othervn_list')                 ///
         matrices(`matlist')                           ///
         matnames(`matnames_list')                     ///
         scalars(`scalarlist')                         ///
         scalarnames(`scalarnames')                    ///
         staticscalars(`staticscalars')                ///
         llsetup(stpm3_mlad_ll_setup)                  ///
         `initopt'                                     ///
         `constraints'                                 ///
         `log'                                         ///
         `idopt'                                       ///
         `mlopts'                                      ///
         `robustopt'                                   ///
         `mlmethodopt'                                 ///
         `verbose'                                     ///
         `mladoptions'                                 ///
         minlike allbetas                              ///
         search(off)  
    
    macro drop stpm3_mlad_time_varlist
  }

  capture mata: rmexternal("`stpm3_struct'") 
  
  
  ereturn scalar dev = -2*e(ll)
  ereturn scalar AIC = -2*e(ll) + 2 * e(rank) 
  qui count if `touse' & _d
  ereturn scalar BIC = -2*e(ll) + ln(r(N)) * e(rank) 


  ereturn local constant         `constant' 
  ereturn local varlist          `varlist'
  ereturn local varlist_original `varlist_original'
  ereturn local tvc              `tvc'
  ereturn local tvc_original     `tvc_orignal'
  ereturn local tvc_included     `tvc_included'
  ereturn local splinelist       `splinelist'
  ereturn local splinelist_tvc   `splinelist_tvc'
  ereturn local splinevars_tvc   `splinevars_tvc'
  ereturn local dsplinevars      `alldsplinevars'
  ereturn local knots            `knots'
  ereturn local dfbase           `df'
  
  
  
  ereturn local sharedtvc_knots `sharedtvc_knots'

  if "`tvc'" != "" {
    fvrevar `tvc', list
    local tvcvars `r(varlist)'
    ereturn local tvcvars `tvcvars'
    if `sharedtvc_knots' {
      ereturn local knots_tvc        `knots_tvc'
    }
    else {
      foreach v in `tvcvars' {
        ereturn local knots_tvc_`v'  `knots_tvc_`v''
      }
    }
  }

  ereturn local python           `python'
  ereturn local splinetype       `splinetype'
  ereturn local ttrans           `ttrans'
  ereturn local degree           `degree'
  ereturn local scale            `scale'
  ereturn local offset           `offset'
  ereturn local model_vars       `model_vars'
  ereturn local ef_varlist       `ef_varlist'
  ereturn local noconstant       `constant'
  ereturn local bhazard          `bhazard'
  foreach v in `ef_varlist' {
    ereturn local ef_`v'_Nfn `ef_`v'_Nfn'
    forvalues i = 1/`ef_`v'_Nfn' {
      ereturn local  ef_`v'_fn`i'     `ef_`v'_fn`i''
      ereturn local  ef_`v'_opts`i'   `ef_`v'_opts`i''
      ereturn local  ef_`v'_knots`i'  `ef_`v'_knots`i''
      ereturn local  ef_`v'_degree`i' `ef_`v'_degree`i''
      ereturn local  ef_`v'_winsor`i' `ef_`v'_winsor`i''
      ereturn local  ef_`v'_powers`i' `ef_`v'_powers`i''
      ereturn local  ef_`v'_scale`i'  `ef_`v'_scale`i''
      ereturn local  ef_`v'_center`i' `ef_`v'_center`i''
    }
  }
  ereturn local ef_Nuser `ef_Nuser'
  ereturn local ef_fn_names `fn_names'
  forvalues i = 1/`ef_Nuser' {
    ereturn local ef_fn`i'_function `ef_fn`i'_function'
    ereturn local ef_fn`i'_centerval `ef_fn`i'_centerval'
    ereturn local ef_fn`i'_opts `ef_fn`i'_opts'
  }
  if "`scale'" == "lnhazard" {
    ereturn local nodes `nodes'
    ereturn local integ_method = cond("`allnum'"!="","allnum","3part")
    ereturn local quadrature = cond("`tanhsinh'"!="","tanhsinh","legendre")
    if "`tanhsinh'" != "" ereturn local tanhsinh_N = `tanhsinh_N'
  }
  ereturn local predict stpm3_pred
  
  
  if `empty_varlist' local eform
  Replay,  `eform' `diopts' `header' neq(`neq') 
end

program Replay
  syntax [, EFORM noHEADer neq(integer 2) * ]
  _get_diopts diopts, `options'

   ml display, `eform' `diopts' `header' neq(`neq')
   if "`e(scale)'" == "lnhazard" {
     local quadmethod = cond("`e(quadrature)'"=="tanhsinh",             ///
                             "tanh-sinh","Gauss-Legendre")
     di as result "Quadrature method: `quadmethod' with `e(nodes)' nodes."
     if "`e(integ_method)'" == "3part" {
       di as result "Analytical integration before first and after last knot."
     }              
     if "`e(python)'" != "" {
       di as result "log-likelihood, gradient and Hessian calculated in Python."
     }
   }
   local j 1
   if "`e(ef_varlist)'" != "" {
     di as result "Extended functions"
     foreach v in `e(ef_varlist)' {
       forvalues i = 1/`e(ef_`v'_Nfn)' {
         di as result " (`j') @`e(ef_`v'_fn`i')'(`v', `e(ef_`v'_opts`i')')"       
         local ++j
       }
     }
   }
   if `e(ef_Nuser)'>0 {
     forvalues i = 1/`e(ef_Nuser)' {
       di as result " (`j') @fn(`e(ef_fn`i'_function)', `e(ef_fn`i'_opts)')"
       local ++j
     }
   }
end


// Initial values for Cox model
// need to add  bhazard
// need to add  offset
// need to pass inittheta
// need to pass nocons
// add code for theta models

///////////////////////////////////////////////////
/////////////// Initial Values ////////////////////
///////////////////////////////////////////////////
program define CoxInit, rclass
  syntax [varlist(fv default=empty)] [if][in], scale(string)         ///
                                               splinevars(string)    ///
                                               hasdelentry(string)   ///
                                               [noconstant           ///
                                               bhazard(string)       ///
                                               splinetvcvars(string) ///
                                               model(string)         ///
                                               ]
  marksample touse
  tempvar coxindex expindex S Sadj Z hadj
  
  if !inlist("`model'","cox","weibull","exp","stpm2") {
    di as error "Illegal model for initial values"
    exit 198
  }
  
  local bhazinit 0.2

  
  if "`model'" == "cox" {
    qui stcox `varlist' if `touse', estimate 
    qui predict double `coxindex' if `touse', xb
    qui sum `coxindex' if `touse'
    qui replace `coxindex'=`coxindex'-`r(mean)' if `touse'
    qui stcox `coxindex' if `touse', 
    qui predict double `S' if `touse', basechazard
    qui replace `S' = exp(-`S')
    if "`bhazard'" != "" {
      qui replace `S' = `S'/exp(-`bhazinit'*`bhazard'*_t) if `touse'
    }
    qui predict double `Sadj' if `touse', hr
    qui replace `Sadj'=`S'^`Sadj' if `touse'
  }
  else if "`model'" == "exp" {
    qui streg `varlist' if `touse', dist(exp) 
    local predopt = cond("`scale'"!="lnhazard","csurv","hazard")
    qui predict double `Sadj' if `touse', `predopt'
    if "`bhazard'" != "" {
      qui replace `Sadj' = `Sadj'/exp(-`bhazinit'*`bhazard'*_t)
    }    
  }
  else if "`model'" == "weibull" {
    qui streg `varlist' if `touse', dist(weib) 
    local predopt = cond("`scale'"!="lnhazard","csurv","hazard")
    qui predict double `Sadj' if `touse', `predopt'  
    if "`bhazard'" != "" {
      qui replace `Sadj' = `Sadj'/exp(-`bhazinit'*`bhazard'*_t)
    }       
  }
  else if "`model'" == "stpm2" {
    if "`bhazard'" != "" local bhazopt bhazard(`bhazard')
    qui stpm2 `varlist' if `touse', df(5) scale(hazard) `bhazopt'  
    qui predict double `Sadj' if `touse', survival 
    
    qui predict double `hadj' if `touse', hazard 
  }  
  
  if "`scale'" == "lncumhazard" {
    qui gen double `Z' = ln(-ln(`Sadj')) `addoff' if `touse'
  }
  else if "`scale'" == "lnodds" {
    qui gen double `Z' = ln((1-`Sadj')/`Sadj')  `addoff'  if `touse'
  } 
  else if "`scale'" == "probit" {
    qui count if `touse'
    local nobs `r(N)'
    qui gen double `Z' = invnormal((`nobs'*(1-`Sadj')-3/8)/(`nobs'+1/4))  `addoff' if `touse'
  }
  else if "`scale'" == "lnhazard" {
    qui gen double `Z' = ln(`Sadj')
  }
  else if "`scale'"=="hazard" {
     qui gen double `Z' = `hadj' 
  }
  
  
  
  qui regress `Z' `varlist' `splinevars' `splinetvcvars' if `touse' & _d == 1 , `constant'
  
  tempname initmat
  matrix `initmat' = e(b)


  // fix to get better starting values for log hazard models
  //if "`scale'" == "lnhazard"  & "`constant'" == "" {
  //   local Ncol: colsof `initmat'
  //   matrix `initmat'[1,`Ncol'] = -0.5
  //}
  
  return matrix initmat = `initmat'
end


////////////////////////////////
// extended functions         //
////////////////////////////////

// stpm3_extract_extfunction
//   -- extracts extended functions from varlist


program define stpm3_extract_extfunction, rclass
  syntax [anything], [tvc]
  if ustrpos("`anything'","@") == 0 {
    return local cleanedvarlist `anything'
    exit
  }
  local tmpstring `anything'
  local extf_count 1
  local anythingret `anything'
  while 1 {
    local extf_start = ustrpos("`tmpstring'","@")
    if `extf_start' == 0 continue, break
    local tmpstring = substr("`tmpstring'",`=`extf_start'+1',.)
    local ts_length  = strlen("`tmpstring'")
      
    local openp 0
    local par_start 0
    forvalues i = 1/`ts_length' {
      local c = substr("`tmpstring'",`i',1)
      local extfunc`extf_count' `"`extfunc`extf_count''`c'"' 
      if "`c'" == "(" {
        if `openp' == 0 local par_start 1 
        local ++openp
      }
      if "`c'" == ")" {
        local --openp
      }      
      if `par_start' & (`openp' == 0) {
        local extfunc`extf_count'_original `extfunc`extf_count''
        local allopts
        stpm3_extfun_options, `extfunc`extf_count''

        if inlist("`r(functype)'","ns","bs","rcs","fp","poly") {
          foreach opt in df bknots allknots knots degree winsor powers scalev centerv {
            if "`r(`opt')'" != "" local allopts `allopts' `opt'(`r(`opt')')
          }
          foreach opt in center scale {
            if "`r(`opt')'" != "" local allopts `allopts' `r(`opt')'
          }
          local extfunc`extf_count' `r(functype)'(`r(varname)', `allopts')
          local anythingret = subinstr("`anythingret'","@"+"`extfunc`extf_count'_original'","@"+"`extfunc`extf_count''",.)
        }
        else if "`r(functype)'" == "fn" {
          foreach opt in df center centerv stub {
            if "`r(`opt')'" != "" local allopts `allopts' `opt'(`r(`opt')')
          }          
          local extfunc`extf_count' `r(functype)'(`r(function)',`allopts')
          local anythingret = subinstr("`anythingret'","@"+"`extfunc`extf_count'_original'","@"+"`extfunc`extf_count''",.)
        }
        
        local ++extf_count
        local par_start 0
        //local tmpstring = substr("`anything'",`=`extf_start'+1',.)
        continue, break
      }
    }
  }
  local --extf_count
  forvalues i = 1/`extf_count' {
    local extfunclist `"`extfunclist' "`extfunc`i''""'
  }
  
  return local cleanedvarlist `"`anythingret'"'
  return local extfunclist = `"`extfunclist'"'
  
end


program define stpm3_gen_extended_functions, rclass
  syntax [anything] [if][in], [xb(string) tvc(string)]
  
  marksample touse
  local j 1 // new numbering (for repeats)
  local o 0 // orginal numbering
  local ef_Nuser 0 // number of user functions
  foreach ef in `anything' {
    local ++o
    local extfunc_o`o' `ef'
    
    stpm3_extfun_options, `ef'
    local allopts

    if inlist("`r(functype)'","bs","ns","rcs") {
      foreach opt in df bknots allknots knots degree winsor centerv {
        if "`r(`opt')'" != "" local allopts `allopts' `opt'(`r(`opt')')
      }
      local allopts `allopts' `r(center)'
    }
    else if "`r(functype)'" == "fp" {
      foreach opt in powers scalev centerv {
        if "`r(`opt')'" != "" local allopts `allopts' `opt'(`r(`opt')')
      }
      local allopts `allopts' `r(scale)' `r(center)'
    }
    else if "`r(functype)'" == "poly" {
      foreach opt in degree centerv  {
        if "`r(`opt')'" != "" local allopts `allopts' `opt'(`r(`opt')')
      }
      local allopts `allopts' `r(center)'
    }
    else if "`r(functype)'" == "fn" {
      foreach opt in stub centerv {
        if "`r(`opt')'" != "" local allopts `allopts' `opt'(`r(`opt')')
      }
      local allopts `allopts' `r(center)'
    }
    // new function if no previous extfunction with varname
    if "`r(functype)'" != "fn" {
      local v `r(varname)'
      if  subinword("`ef_varlist'","`v'","",1) == "`ef_varlist'" {               
        local ef_varlist `ef_varlist' `v'
        local ef_`v'_fn1   `r(functype)'
        local ef_`v'_opts1 `allopts'
        local ef_`v'_Nfn =  1
        local Nf `ef_`v'_Nfn'
        local newfunc 1
        local efmatch_`v' `o'
      }
      else {
        // check if varname in previous ext function is the same.
        local Nf `ef_`v'_Nfn'
        local newfunc 1
        forvalues f=1/`Nf' {
          if ("`ef_`v'_fn`f''" == "`r(functype)'") & ///
             ("`ef_`v'_opts`Nf''" == "`allopts'") {
              local newfunc 0
          }
        }
        if `newfunc' {
          local ++Nf
          local ++ef_`v'_Nfn
          local ef_`v'_fn`Nf' `r(functype)'
          local ef_`v'_opts`Nf' `allopts'   
          if subinword("`ef_varlist'","`v","",1) != "`ef_varlist'" {
            local ef_varlist `ef_varlist' `v'
          }
          local efmatch_`v' `efmatch_`v'' `o'
        }
        local efmatch_`v' `efmatch_`v'' `o'
      }
    }
    else {
      // check if new function
      local newfunc 1
      if `ef_Nuser'>=1 {
        forvalues i = 1/`ef_Nuser' {
          if "`r(function)'" == "`ef_fn`i'_function'" {
            local newfunc 0
            continue, break
          }
        }
      }
      
      if `newfunc '{      
        local ++ef_Nuser
        local ef_fn_varlist `ef_fn_varlist' `r(expvarnames)'
        local ef_fn_varlist: list uniq ef_varlist
        local ef_fn`ef_Nuser'_varlist `r(expvarnames)'
        local userfunc`ef_Nuser' `ef'       
        local ef_fn`ef_Nuser'_function `r(function)'
        local ef_fn`ef_Nuser'_stub `r(stub)'
        local ef_fn`ef_Nuser'_opts `allopts'
      }    
    }

    if `newfunc' {
      local add_v_extend`j'
      local functype `r(functype)'
      if inlist("`functype'","ns","bs","rcs") {
        gensplines `v', `allopts' gen(_`r(functype)'_f`Nf'_`v') ///
                               type(`r(functype)')
        local ef_`v'_center`Nf' `r(center)'                                   
        local ef_`v'_knots`Nf'  `r(knots)'                                   
        local ef_`v'_winsor`Nf' `r(winsor)'                                   
        if "`functype'" == "bs" local ef_`v'_degree`Nf' `r(degree)'
      }
      else if "`functype'" == "fp" {
        stpm3_fpgen `v', `allopts' stub(_fp_f`Nf'_`v')
        local ef_`v'_powers`Nf' `r(powers)'                                   
        local ef_`v'_center`Nf' `r(center)'                                   
        local ef_`v'_scale`Nf'  `r(scale)'                                   
      }
      else if "`functype'" == "poly" {
        stpm3_polygen `v', `allopts' stub(_poly_f`Nf'_`v')
        local ef_`v'_degree`Nf' `r(degree)'                                   
        local ef_`v'_center`Nf' `r(center)'                                   
      }
      else if "`functype'" == "fn" {
        local vname  = cond("`r(stub)'"=="","f`ef_Nuser'","`r(stub)'")
        local fn_names `fn_names' `vname'
        local ef_`ef_Nuser' `ef'
        stpm3_userfunc `r(function)', `allopts' vname(_fn_`vname')
        local ef_fn`ef_Nuser'_centerval `r(fncenter)'
      }      

      if "`functype'" != "fn" {
        local  `v'_f`Nf'_vars `r(splinevarlist)' `r(fpvars)' `r(polyvars)'                                  
        foreach k in `r(splinevarlist)' `r(fpvars)' `r(polyvars)' `r(fnvarname)' {
          local add_v_extend`j' `add_v_extend`j'' `k'
        }
      
        local add_v_extend`j' c.(`add_v_extend`j'')
        local ++j
      }
      else {
        local add_v_userfunc`ef_Nuser' c.(`r(fnvarname)')
      }
      local newfunc 0
    }
  }
  
  // check center is consistant over extended functions
  foreach v in `ef_varlist' {
    if `ef_`v'_Nfn' == 1 continue
    local allcenter
    forvalues i = 1/`ef_`v'_Nfn' {
      local tmpcen = cond("`ef_`v'_center`i''"!="","`ef_`v'_center`i''","")
      local allcenter `allcenter' `tmpcen'
    }
    local cenunique: list uniq allcenter
    forvalues i = 1/`ef_`v'_Nfn' {
      if "`cenunique'" != "`ef_`v'_center`i''" {
        di as error "When using center() option, you must use the same center value for the same variable"
        exit 198
      }
    }
  }

  // substitute spline functions into xb and tvc
  foreach v in `ef_varlist' {
    local efmatch_`v': list uniq efmatch_`v'
    local firstm = word("`efmatch_`v''",1)
    foreach m in `efmatch_`v'' {
      local xb = subinstr("`xb'","@"+"`extfunc_o`m''","`add_v_extend`m''",.)
      if "`tvc'" != "" & strpos("`tvc'","`extfunc_o`m''") {
        local tvc = subinstr("`tvc'","@"+"`extfunc_o`m''","`add_v_extend`m''",.)
      }      
    }
  }  
  forvalues i =1/`ef_Nuser' {
    local xb = subinstr("`xb'","@"+"`userfunc`i''","`add_v_userfunc`i''",.)
      if "`tvc'" != "" {
        local tvc = subinstr("`tvc'","@"+"`userfunc`i''","`add_v_userfunc`i''",.)
    }          
  }  
  // obtain model_vars  
  fvrevar `xb' `tvc', list
  local model_vars `r(varlist)'
  foreach v in `ef_varlist' {
    forvalues f = 1/`ef_`v'_Nfn' {
      foreach v2 in ``v'_f`f'_vars' {
        local model_vars = subinstr("`model_vars'","`v2'","",.)
      }
    }
  }

  forvalues i = 1/`ef_Nuser' {
    local fnname = "_fn_`=word("`fn_names'",`i')'"
    local model_vars = subinstr("`model_vars'","`fnname'","`ef_fn`i'_varlist'",.)
  }
  local model_vars `model_vars' `ef_varlist'
  local model_vars: list uniq model_vars
  
  // send back to main stpm3 program
  c_local ef_varlist `ef_varlist'
  foreach v in `ef_varlist' {
    c_local ef_`v'_Nfn `ef_`v'_Nfn'
    forvalues i = 1/`ef_`v'_Nfn' {
      c_local ef_`v'_fn`i' `ef_`v'_fn`i''
      c_local ef_`v'_opts`i'   `ef_`v'_opts`i''
      if inlist("`ef_`v'_fn`i''","ns","bs","rcs") {
        c_local ef_`v'_center`i' `ef_`v'_center`i''
        c_local ef_`v'_degree`i' `ef_`v'_degree`i''
        c_local ef_`v'_knots`i'  `ef_`v'_knots`i''
        c_local ef_`v'_winsor`i' `ef_`v'_winsor`i''
      }
      else if "`ef_`v'_fn`i''" == "fp" {
        c_local ef_`v'_powers`i' `ef_`v'_powers`i''
        c_local ef_`v'_scale`i'  `ef_`v'_scale`i''
        c_local ef_`v'_center`i' `ef_`v'_center`i''        
      }
      else if "`ef_`v'_fn`i''" == "poly" {
        c_local ef_`v'_powers`i' `ef_`v'_degree`i''
        c_local ef_`v'_center`i' `ef_`v'_center`i'' 
      }
    }
  }
  c_local ef_Nuser `ef_Nuser'
  c_local fn_names `fn_names'
  forvalues i = 1/`ef_Nuser' {
    c_local ef_fn`i'_function `ef_fn`i'_function'
    c_local ef_fn`i'_varlist `ef_fn`i'_varlist'
    c_local ef_fn`i'_centerval `ef_fn`i'_centerval'  
    c_local ef_fn`i'_opts `ef_fn`i'_opts'  
  }  
  c_local varlist `xb'
  c_local tvc `tvc'
  c_local model_vars `model_vars'

end


// scale option
program define getscaleoption,
  syntax , [ /*HAZARD*/              ///
            LNCUMHazard LOGCUMHazard ///
            LNHazard  LOGHazard      ///
            LNODDs    LOGODDs        ///
            PROBit]
  if "`logcumhazard'" != "" local lncumhazard lncumhazard
  if "`loghazard'"    != "" local lnhazard lnhazard
  if "`logodds'"    != ""   local lnodds lnodds
  if "`lncumhazard'`lnhazard'`lnodds'`probit'`hazard'" == "" {
    di as error "You must specify the scale option."
    exit 198
  }
  c_local scale `lncumhazard'`lnhazard'`lnodds'`probit'`hazard'
end  

  
// this should return the options in a particlar order
program define stpm3_extfun_options, rclass
  syntax          , [ns(string) bs(string)   rcs(string) ///
                     fp(string) poly(string) fn(string)]
  
  local functype = cond("`ns'"   != "","ns",    ///
                   cond("`bs'"   != "","bs",    ///
                   cond("`rcs'"  != "","rcs",   ///
                   cond("`fp'"   != "","fp",    ///
                   cond("`poly'" != "","poly",  ///
                   "fn")))))

  local 0 `ns'`bs'`rcs'`fp'`poly'`fn'
  if "`ns'`bs'`rcs'" != "" {
    syntax varname, [allknots(string)     ///
                     bknots(string)     ///
                     CENTer                          ///
                     CENTerv(numlist min=1 max=1)    ///
                     degree(integer 3)               ///
	                   df(string)                      ///
                     knots(string)        ///
                     LNTime                          ///
                     PERCentile                      ///
                     winsor(string)                  ///
                     ]
                     
    return local varname    `varlist'
    return local df         `df'   
    return local allknots   `allknots'
    return local knots      `knots'
    return local center     `center'
    return local centerv    `centerv'
    return local lntime     `lntime'
    return local percentile `percentile'
    return local winsor     `winsor' 
    return local functype   `functype'
    if "`bs'" != "" return local degree `degree'
  }
  else if "`fp'" != "" {
    syntax varname,    POWers(numlist sort)          ///
                       [                             ///
                       CENTer                        /// 
                       CENTerv(numlist min=1 max=1)  ///
                       SCAle                         ///
                       SCAlev(numlist min=2 max=2)   ///
                       ]
    return local varname `varlist'
    return local powers  `powers'
    return local center  `center'
    return local scale   `scale'
    return local centerv `centerv'
    return local scalev  `scalev'    
    return local functype fp
  }
  else if "`poly'" != "" {
    syntax varname,    DEGree(numlist max=1)         ///
                       [                             ///
                       CENTer                        /// 
                       CENTerv(numlist min=1 max=1)  ///
                       ]    
    return local varname `varlist'
    return local degree  `degree'
    return local center  `center'
    return local centerv `centerv'
    return local functype poly                       
  }
  else if "`fn'" != "" {
  	syntax anything, [stub(string) CENTER CENTerv(numlist min=1 max=1)]
    expr_query `anything'
    return local expvarnames `r(varnames)'
    return local function `anything'
    return local stub `stub'
    return local center  `center'
    return local centerv `centerv'
    return local functype fn
  }  
end

program define parse_integ_options
  syntax, [tanhsinh gl N(real 3) allnum ttrans(string)]
  
  if "`tanhsinh'" != "" & "`gl'" != "" {
    di as error "Only one of the tanhsinh or gl options can be used."
    exit 198
  }
  if "`gl'" != "" local gausslegendre gausslegendre
  if "`tanhsinh'`gausslegendre'" == "" {
    if "`ttrans'" == "lnt" local tanhsinh tanhsinh
    else local gausslegendre `gausslegendre'
  }
  c_local tanhsinh      `tanhsinh'
  c_local gausslegendre `gausslegendre'
  c_local tanhsinh_N    `n'
  c_local allnum        `allnum'
end
 
 