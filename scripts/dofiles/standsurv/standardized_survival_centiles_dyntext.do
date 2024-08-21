
// delete when standsurv on SSC
clear all
adopath ++ "${DRIVE}/GitSoftware/standsurv/standsurv"
cd "${DRIVE}/GitSoftware/standsurv/Testing"
// check no errors
do ../standsurv/standsurv.ado
// read in all mata code.
do ../standsurv/read_mata_files.do

cd "${DRIVE}/github/pclambert/scripts/dofiles/standsurv/"
dyntext standardized_survival_centiles.txt, ///
        saving(../../../software/standsurv/standardized_survival_centiles.qmd) replace
	
	
		
