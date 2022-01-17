#! /bin/bash

PARM_NAME="Mt23_O_500.parm7"
TRAJ_DIR="../../Trayectoria/"
CENTER_RES="87" #phe
mkdir raws 2>/dev/null


#### crea lista de Agua y peroxido con las ids originales
TEMP_F=$(mktemp)
cat << EOF > "${TEMP_F}"
parm ../../"${PARM_NAME}"
trajin ${TRAJ_DIR}100ns.nc 1 1
printatoms :WAT out WAT.dat
printatoms :AOX out AOX.dat
run
exit
EOF
cpptraj -i "${TEMP_F}" 2>&1 /dev/null
wait
#

### Busca en la lista el resid del primer agua y peroxido (con un par de testeos de OK)

WAT_F=$(head -n 2 < WAT.dat | tail -n 1 | awk '{print $3}')
AOX_F=$(head -n 2 < AOX.dat | tail -n 1 | awk '{print $3}')
re='^[0-9]+$'
if [ -z "$WAT_F" ] || [[ ! "$WAT_F" =~ $re ]]; then echo "Error en numero Aguas ####${WAT_F}#######"; exit
elif [ -z "$WAT_F" ] || [[ ! "$WAT_F" =~ $re ]] ; then echo "Error en numero Aguas ####${WAT_F}#######"; exit
else echo "Usando como primer Agua $WAT_F, primer Peroxido $AOX_F"; fi

## corrige la lista de aguas y peroxidos para coincidir con los resid originales


LIST_AOX_A=$(mktemp); LIST_AOX_C=$(mktemp); LIST_WAT_A=$(mktemp); LIST_WAT_C=$(mktemp)
awk -v var="$AOX_F" '{print $1+var-4}' AOX_CA.txt >> $LIST_AOX_A
awk -v var="$AOX_F" '{print $1+var-4}' AOX_CC.txt >> $LIST_AOX_C
awk -v var="$WAT_F" '{print $1+var-4}' H2O_CA.txt >> $LIST_WAT_A
awk -v var="$WAT_F" '{print $1+var-4}' H2O_CC.txt >> $LIST_WAT_C

## Crea inputs cpptraj que extraen los xyz de esos residuos en el tiempo

echo -e "parm ../../${PARM_NAME} \n trajin ${TRAJ_DIR}[0-5]00ns.nc \n autoimage \n center :${CENTER_RES} \n image center familiar" >> BASE_TXT

function cpp_input () {
COUNTER=0
cp BASE_TXT "$2"

for i in $(cat $1)
do
COUNTER=$(( COUNTER + 1 ))
echo "vector AOX${i} dipole out ./raws/dipo_${i}.dat :${i} magnitude" >> "$2"

    if [ $(( COUNTER % 500 )) -eq 0 ] ; then
        echo -e "run \n clear all \n" >> "$2"
        cat BASE_TXT >> "$2"
    fi

done

echo -e "run \n exit" >> "$2"
}


cpp_input $LIST_AOX_A AOX_A.cppin
cpp_input $LIST_AOX_C AOX_C.cppin
cpp_input $LIST_WAT_A WAT_A.cppin
cpp_input $LIST_WAT_C WAT_C.cppin



