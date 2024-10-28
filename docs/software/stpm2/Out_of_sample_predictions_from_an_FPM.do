
// Prepare data
//------------------------------------------------------------------------
use https://www.pclambert.net/data/simulated_survival, clear
tab stage, gen(stage)
gen female = sex == 1 
gen age_centre = age - 70

// Model fitting
//------------------------------------------------------------------------
stset exit, origin(dx) fail(status==1) scale(365.25) ///
exit(time dx+10*365.25)

stpm2 age_centre female stage2 stage3, df(5) scale(hazard) noorthog

// Predictions using the model in memory
//------------------------------------------------------------------------
range timevar10 0 10 100
predict s0, zeros surv timevar(timevar10)
predict s1, at(age_centre 10 female 1 stage2 1) zeros surv timevar(timevar10)
predict s2, at(age_centre 15 stage3 1) zeros surv timevar(timevar10)

// Using the .ster file
//------------------------------------------------------------------------
estimates use https://www.pclambert.net/data/oosmodel.ster
predict s0_ster, zeros surv timevar(timevar10)
predict s1_ster, at(age_centre 10 female 1 stage2 1) zeros surv timevar(timevar10)
predict s2_ster, at(age_centre 15 stage3 1) zeros surv timevar(timevar10)

// Predictions using the model coefficients and knot locations
//------------------------------------------------------------------------
// Calculate the splines for log time
gen double lntime = ln(timevar10)
rcsgen lntime, gen(z) knots(-5.875508413078693 -0.6125073943959456 ///
0.4430906852086161 1.156903994968461 1.750977782183514 2.302560494813347)

// Calculate the log cumulative hazard
gen double logCH_0 = -3.6544747 + 0.8072818*z1 + 0.00931881*z2 + -0.02254634*z3 + ///
0.01779351*z4 + -0.00385097*z5
gen double logCH_1 = logCH_0 + 10*0.02881744 + -0.07721197 + 1.2119145  
gen double logCH_2 = logCH_0 + 15*0.02881744 + 3.0784783 

// Transform to the survival scale
gen double s0_rcs = exp(-exp(logCH_0))
gen double s1_rcs = exp(-exp(logCH_1))
gen double s2_rcs = exp(-exp(logCH_2))

// S(0) = 1
forvalues i = 0/2 {
	replace s`i'_rcs = 1 in 1
}

// Check the approaches agree
summ s0* s1* s2*
