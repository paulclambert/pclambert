clear all

cd ${DRIVE}/GitSoftware/stpm3/stpm3
do stpm3_read_matafiles.do
do stpm3.ado
do stpm3_fpgen.ado
do stpm3_gensplines.ado
do stpm3_polygen.ado
adopath ++"${DRIVE}/GitSoftware/stpm3/stpm3


cd ${DRIVE}/GitSoftware/stpm3/stpm3_pred
do stpm3_pred_read_matafiles.do
do stpm3_pred.ado
adopath ++"${DRIVE}/GitSoftware/stpm3/stpm3_pred
adopath ++"${DRIVE}/GitSoftware/stpm3/stpm3_extra/stpm3km
adopath ++"${DRIVE}/GitSoftware/stpm3/stpm3quadchk/stpm3quadchk


cd "${DRIVE}/github/pclambert/scripts/dofiles/stpm3/"
dyntext relative_survival_models.txt, saving(../../../software/stpm3/relative_survival_models.qmd) replace
	
      