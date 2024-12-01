program weibull_d2
  version 16.1
  args todo b lnf g H
  
  tempvar lnlambda lngamma
  mleval `lnlambda' = `b', eq(1)
  mleval `lngamma'  = `b', eq(2)
  
  mlsum `lnf' = _d*(`lnlambda' + `lngamma' + (exp(`lngamma') - 1)*ln(_t)) - exp(`lnlambda')*_t^(exp(`lngamma')) 
  if (`todo'==0 | `lnf'>=.) exit
  
  tempname dxb1 dxb2

  mlvecsum `lnf' `dxb1' =  _d - exp(`lnlambda')*_t^(exp(`lngamma')), eq(1)
  mlvecsum `lnf' `dxb2' =  _d*(1 + exp(`lngamma')*ln(_t)) - exp(`lnlambda')*_t^exp(`lngamma')*ln(_t)*exp(`lngamma'), eq(2)
  matrix `g' = (`dxb1',`dxb2')
  if (`todo'==1) exit

  tempname d11 d12 d22
  mlmatsum `lnf' `d11' = -exp(`lnlambda')*_t^(exp(`lngamma')), eq(1)
  mlmatsum `lnf' `d12' = -exp(`lnlambda')*_t^exp(`lngamma')*ln(_t)*exp(`lngamma'), eq(1,2)
  mlmatsum `lnf' `d22' = -ln(_t)*exp(`lngamma')*(exp(`lnlambda')*_t^exp(`lngamma')*ln(_t)*exp(`lngamma')+exp(`lnlambda')*_t^exp(`lngamma')-_d), eq(2)
  matrix `H' = (`d11',`d12' \ `d12'',`d22')  
end
