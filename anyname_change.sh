#! /bin/bash
shopt -s lastpipe


PIPNAME="Mt23_O_500"
RESIDUOS_C="657,665,680"
RESIDUOS_A="87,95,110"


echo "Recordar cambiar PIPNAME y residuos"
echo "PIPNAME ACTUAL $PIPNAME"
echo "Resid actuales A=$RESIDUOS_A; C=$RESIDUOS_C"
read -p 'Proseguir? y/n: ' SEGUIR

if [ "$SEGUIR" == "n" ]
    then exit
elif [ "$SEGUIR" == "y" ]
    then echo "...OK..."
else echo "ERROR"; exit
fi

read -p 'Parallel: Cuantos Nucleos? ' CORE
read -p 'Parallel: Contar threads? (Solo OpenMPI) y/n ' MPI


CPPFILE_CHAINS=$(mktemp)
CPPFILE_PDBS=$(mktemp)
CPPFILE_NCS=$(mktemp)

### Detectar Cadenas
cat << EOF > "${CPPFILE_CHAINS}"
parm ../../${PIPNAME}.parm7
trajin ../../Trayectoria/100ns.nc 1 1
trajout Cadenas.pdb
EOF
cpptraj -i "${CPPFILE_CHAINS}" &>/dev/null

TER=()
grep -E "OXT"  < Cadenas.pdb | awk '{print $5}' | while IFS="" read -r line; do TER+=("$line"); done
rm Cadenas.pdb


function CP_INPUT ()  {

TER=$2

echo -e "parm ../../${1}.parm7 \ntrajin ../../Trayectoria/100ns.nc ${10} \nautoimage" >> "$6"
echo -e "center :1-${TER[0]}\ncenter :1-${TER[1]}\ncenter :1-${TER[2]}\ncenter :1-${TER[3]}\nimage center familiar" >> "$6"
echo "strip \"!(:${7} | :${8}&@CA)\"" >> "$6"
echo "trajout ${9}" >> "$6"
echo -e "run \n clear all" >> "$6"
}


CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_PDBS" "AOX&@O1" ${RESIDUOS_A} "AOX_CA.pdb" "1 1"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_PDBS" "AOX&@O1" ${RESIDUOS_C} "AOX_CC.pdb" "1 1"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_PDBS" "WAT&@O" ${RESIDUOS_A} "WAT_CA.pdb" "1 1"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_PDBS" "WAT&@O" ${RESIDUOS_C} "WAT_CC.pdb" "1 1"


CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_NCS" "AOX&@O1" ${RESIDUOS_A} "AOX_CA.nc"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_NCS" "AOX&@O1" ${RESIDUOS_C} "AOX_CC.nc"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_NCS" "WAT&@O" ${RESIDUOS_A} "WAT_CA.nc"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_NCS" "WAT&@O" ${RESIDUOS_C} "WAT_CC.nc"


#DEBUG
cp "$CPPFILE_PDBS" DEB_PDB
cp "$CPPFILE_NCS" DEB_NC

cpptraj -i "$CPPFILE_PDBS"

if [ "$MPI" == "n" ]
    then mpirun -np ${CORE} cpptraj.MPI -i "${CPPFILE_NCS}"
elif [ "$MPI" == "y" ]
    then mpirun --use-hwthread-cpus -np ${CORE} cpptraj.MPI -i "${CPPFILE_NCS}"
else echo "ERROR"; exit
fi

