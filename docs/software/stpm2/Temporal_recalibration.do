
// Graph settings
//------------------------------------------------------------------------
grstyle init
grstyle set plain, horizontal grid 
grstyle set legend 4, nobox
grstyle set color 538
grstyle set horizontal
grstyle set margin "0mm 0mm 0mm 0mm": twoway

// Clean data
//------------------------------------------------------------------------
use https://www.pclambert.net/data/simulated_improvements, clear
tab stage, gen(stage)
gen female = sex == 1 
gen age_centre = age-70

// Model fitting
//------------------------------------------------------------------------

// Standard method
stset exit if val==0, origin(dx) fail(status==1) scale(365.25) ///
exit(time min(dx+10*365.25,mdy(12,31,2019)))

stpm2 age_centre female stage2 stage3, df(3) scale(hazard) noorthog
estimates store standard
predict lp, xbnobaseline

// Temporal recalibration with a 5 year window
stset exit if val==0, origin(dx) fail(status==1) scale(365.25) ///
entry(time mdy(1,1,2015)) exit(time min(dx+10*365.25,mdy(12,31,2019)))

constraint 1 _b[lp] = 1
stpm2 lp, scale(hazard) noorthog constraints(1) df(3) 
estimates store recal5 

// Temporal recalibration with a 2 year window
stset exit if val==0, origin(dx) fail(status==1) scale(365.25) ///
entry(time mdy(1,1,2018)) exit(time min(dx+10*365.25,mdy(12,31,2019)))

stpm2 lp, scale(hazard) noorthog constraints(1) df(3) 
estimates store recal2

// 10-year predictions
//------------------------------------------------------------------------
gen t10 = 10

// Standard method
estimates restore standard
predict standard_10 if val==1, surv timevar(t10)

// Temporal recalibration
foreach model in "recal5" "recal2" {
	estimates restore `model'
	predict `model'_10 if val==1, surv timevar(t10)
}

// Comparison
summ standard_10 recal5_10 recal2_10
twoway (histogram standard_10, start(0) width(0.008) ///
       col("3 144 214%50") freq) /// 
	   (histogram recal2_10, start(0) width(0.008) ///
	   col("120 172 68%50") freq xtitle("10-Year Survival") ///
	   legend(order(1 "Standard" 2 "Temporal Recalibration: 2 Year Window") ///
	   symxsize(3) ring(0) pos(11)) xlabel(,format(%3.1f))) 	
	   
// Individual predictions
//------------------------------------------------------------------------
range timevar10 0 10 101

// Standard method
estimates restore standard
predict p1_standard, zeros surv timevar(timevar10)
predict p2_standard, at(age_centre 12 female 1 stage2 1) ///
	                 zeros surv timevar(timevar10)
predict p3_standard, at(age_centre -17 female 1 stage3 1) ///
                     zeros surv timevar(timevar10)
predict p4_standard, at(age_centre 15 stage3 1) ///
                     zeros surv timevar(timevar10)

// Temporal recalibration
estimates restore standard
local p2 = _b[age_centre]*12 + _b[female] + _b[stage2] 
local p3 = _b[age_centre]*(-17) + _b[female] + _b[stage3] 
local p4 = _b[age_centre]*(15) + _b[stage3] 

foreach model in "recal5" "recal2" {
	estimates restore `model'
	predict p1_`model', zeros surv timevar(timevar10)
	predict p2_`model', at(lp `p2') zeros surv timevar(timevar10)
	predict p3_`model', at(lp `p3') zeros surv timevar(timevar10)
	predict p4_`model', at(lp `p4') zeros surv timevar(timevar10)
}

// Comparison
line p1_standard timevar10, sort || ///
line p1_recal5 timevar10, sort || ///
line p1_recal2 timevar10, sort xtitle("Years since Diagnosis") ///
ytitle("Survival Proportion") name(p1,replace) ///
legend(order(1 "Standard" 2 "Temporal Recalibration: 5 Year Window" ///
3 "Temporal Recalibration: 2 Year Window") size(small)) ///
subtitle("70, Male, Stage 1") ysc(r(0 1)) ylabel(0(0.2)1) ylabel(,format(%3.1f))

line p2_standard timevar10, sort || ///
line p2_recal5 timevar10, sort || ///
line p2_recal2 timevar10, sort xtitle("Years since Diagnosis") ///
ytitle("Survival Proportion") name(p2,replace) ///
legend(order(1 "Standard" 2 "Temporal Recalibration: 5 Year Window" ///
3 "Temporal Recalibration: 2 Year Window") size(small)) ///
subtitle("82, Female, Stage 2") ysc(r(0 1)) ylabel(0(0.2)1) ylabel(,format(%3.1f))

line p3_standard timevar10, sort || ///
line p3_recal5 timevar10, sort || ///
line p3_recal2 timevar10, sort xtitle("Years since Diagnosis") ///
ytitle("Survival Proportion") name(p3,replace) ///
legend(order(1 "Standard" 2 "Temporal Recalibration: 5 Year Window" ///
3 "Temporal Recalibration: 2 Year Window") size(small)) ///
subtitle("53, Female, Stage 3") ysc(r(0 1)) ylabel(0(0.2)1) ylabel(,format(%3.1f))

line p4_standard timevar10, sort || ///
line p4_recal5 timevar10, sort || ///
line p4_recal2 timevar10, sort xtitle("Years since Diagnosis") ///
ytitle("Survival Proportion") name(p4,replace) ///
legend(order(1 "Standard" 2 "Temporal Recalibration: 5 Year Window" ///
3 "Temporal Recalibration: 2 Year Window") size(small)) ///
subtitle("85, Male, Stage 3") ysc(r(0 1)) ylabel(0(0.2)1) ylabel(,format(%3.1f))

grc1leg p1 p2 p3 p4

// Marginal survival
//------------------------------------------------------------------------

// Standard method
estimates restore standard
predict marg_standard if val==1, timevar(timevar10) meansurv

// Temporal recalibration
foreach model in "recal5" "recal2" {
	estimates restore `model'
	predict marg_`model' if val==1, timevar(timevar10) meansurv
}

// Observed survival
stset exit if val==1, origin(dx) fail(status==1) scale(365.25) ///
exit(time dx+10*365.25)

sts gen marg_obs = s
gen time = _t

// Comparison
line marg_standard timevar10, sort || ///
line marg_recal5 timevar10, sort || ///
line marg_recal2 timevar10, sort || ///
line marg_obs time, sort c(J) xtitle("Years since Diagnosis") ///
ytitle("Survival Proportion") ysc(r(0.57 1)) ///
legend(order(1 "Standard" 2 "Temporal Recalibration: 5 Year Window" ///
3 "Temporal Recalibration: 2 Year Window" 4 "Observed: KM") ring(0) pos(1)) ylabel(,format(%3.1f))

// Cox models
//------------------------------------------------------------------------
stset exit if val==0, origin(dx) fail(status==1) scale(365.25) ///
exit(time min(dx+10*365.25,mdy(12,31,2019)))

stcox age_centre female stage2 stage3
predict lp_cox, xb

stset exit if val==0, origin(dx) fail(status==1) scale(365.25) ///
entry(time mdy(1,1,2015)) exit(time min(dx+10*365.25,mdy(12,31,2019)))

stcox, estimate offset(lp_cox)
