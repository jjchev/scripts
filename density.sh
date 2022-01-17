#! /bin/bash

shopt -s lastpipe
CPPFILE_CHAINS=$(mktemp)
PARM_NAME="Mt23_O_500.parm7"
TRAJ_DIR="../../Trayectoria/"
mkdir raws 2>/dev/null


# crea lista de Agua y peroxido con las ids originales - crea pdb para extraer cadenas

cat << EOF > "${CPPFILE_CHAINS}"
parm ../../${PARM_NAME}
trajin ../../Trayectoria/100ns.nc 1 1
trajout Cadenas.pdb
printatoms :WAT out WAT.dat
printatoms :AOX out AOX.dat
run
exit
EOF
cpptraj -i "${CPPFILE_CHAINS}" 2>&1 /dev/null
wait


# Extrae numero de cadenas del pdb y guarda en array TER, luego variable CENTER_RES
TER=()
grep -E "TER"  < Cadenas.pdb | awk '{print $4}' | while IFS="" read -r line; do TER+=("$line"); done
CENTER_RES="1-${TER[0]}\ncenter :1-${TER[1]}\ncenter :1-${TER[2]}\ncenter :1-${TER[3]}"



### Busca en la lista el resid del primer agua y peroxido (con un par de testeos de OK)
WAT_F=$(head -n 2 < WAT.dat | tail -n 1 | awk '{print $3}')
AOX_F=$(head -n 2 < AOX.dat | tail -n 1 | awk '{print $3}')
re='^[0-9]+$'
if [ -z "$WAT_F" ] || [[ ! "$WAT_F" =~ $re ]]; then echo "Error en numero Aguas ####${WAT_F}#######"; exit
elif [ -z "$WAT_F" ] || [[ ! "$WAT_F" =~ $re ]] ; then echo "Error en numero Aguas ####${WAT_F}#######"; exit
else echo "Usando como primer Agua $WAT_F, primer Peroxido $AOX_F"; fi
rm WAT.dat; rm AOX.dat


## corrige la lista de aguas y peroxidos para coincidir con los resid originales
LIST_AOX_A=$(mktemp); LIST_AOX_C=$(mktemp); LIST_WAT_A=$(mktemp); LIST_WAT_C=$(mktemp)
awk -v var="$AOX_F" '{print $1+var-4}' AOX_CA.txt >> "$LIST_AOX_A"
awk -v var="$AOX_F" '{print $1+var-4}' AOX_CC.txt >> "$LIST_AOX_C"
awk -v var="$WAT_F" '{print $1+var-4}' H2O_CA.txt >> "$LIST_WAT_A"
awk -v var="$WAT_F" '{print $1+var-4}' H2O_CC.txt >> "$LIST_WAT_C"

## Crea inputs cpptraj que extraen los xyz de esos residuos en el tiempo

echo -e "parm ../../${PARM_NAME} \n trajin ${TRAJ_DIR}[0-5]00ns.nc \n autoimage \n center :${CENTER_RES} \n image center familiar" >> BASE_TXT

function cpp_input () {
COUNTER=0
cp BASE_TXT "$2"

for i in $(cat $1)
do
COUNTER=$(( COUNTER + 1 ))
echo "vector ${RANDOM}_${3}_${i} dipole out ./raws/${3}_dipo_${i}.dat :${i} magnitude" >> "$2"

# Para dividir por partes si no entra en memoria
# if [ $(( COUNTER % 500 )) -eq 0 ] ; then echo -e "run \n clear all \n" >> "$2"; cat BASE_TXT >> "$2"; fi

done

echo -e "run \n exit" >> "$2"
}

cpp_input "$LIST_AOX_A" AOX_A.cppin "AA"
cpp_input "$LIST_AOX_C" AOX_C.cppin "AC"
cpp_input "$LIST_WAT_A" WAT_A.cppin "WA"
cpp_input "$LIST_WAT_C" WAT_C.cppin "WC"

##Para unir todos (si alcanza la memoria) -


rm ALL.TXT; cp BASE_TXT ALL.TXT; cat *.cppin | grep vector >> ALL.TXT; echo -e "run \n exit" >> ALL.TXT; rm BASE_TXT *.cppin







