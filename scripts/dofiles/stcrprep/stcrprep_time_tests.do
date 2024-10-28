use https://www.pclambert.net/data/ebmt1_stata.dta, clear
expand 10
replace time = time + runiform()*0.0001
replace patid = _n
di _N

stset time, failure(status==1) scale(365.25) id(patid) noshow

timer clear
timer on 1
stcrreg i.score, compete(status==2) nolog noshow
timer off 1
timer list

stset time, failure(status==1,2) scale(365.25) id(patid)

timer on 2
stcrprep, events(status) keep(score) trans(1)	
timer off 2
timer list 2

gen	 event = status == failcode
stset tstop [iw=weight_c], failure(event) enter(tstart) 

timer on 3
stcox i.score
timer off 3
timer list
