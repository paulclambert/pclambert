sysuse auto, clear
makespline bspline price, bsepsilon(0)


gensplines price, type(bs) df(4) gen(_bs) intercept
compare vs

regress weight _bsp*, nocons 
regress weight _bs?, 


summ

line _bsp* price, sort
addplot: line _bs? price, sort lpattern(dash..)


sysuse auto, clear
makespline rcs price,  knots(4)
mata: st_local("knots",invtokens(strofreal(st_matrix("r(knots)"))))
gensplines price, type(rcs) allknots(`knots') gen(bob) 


line _* price, sort
line bob* price, sort

gensplines price, type(rcs) df(3) gen(bob) 

summ price
gen frank = (price - `r(min)')/(`r(max)'-`r(min)')
gensplines frank, type(rcs) df(3) gen(bert) 


regress weight _*
regress weight bob*