
// delete when standsurv updated on SSC
clear all
adopath ++ "${DRIVE}/GitSoftware/standsurv/standsurv"
cd "${DRIVE}/GitSoftware/standsurv/Testing"

// check no errors
do ../standsurv/standsurv.ado
// read in all mata code.
do ../standsurv/read_mata_files.do

clear all
cd "${DRIVE}/github/pclambert/scripts/dofiles/standsurv/"
dyntext models_different_countries.txt, saving(../../../software/standsurv/models_different_countries.qmd) replace
	
	
		
	