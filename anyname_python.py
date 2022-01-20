##pasando a pytraj. Resolver image y autoimage (no funciona con iterload / con load es muy grande para memoria). Centrar antes de extraer?


PIPNAME="Mt23_O_500"
RESIDUOS_C="657,665,680"
RESIDUOS_A="87,95,110" #Mt23 87,95,110

import pytraj as pt
traj = pt.iterload('../../Trayectoria/[0-5]ns.nc', 'step5_input.parm7')



import pytraj as pt
traj = pt.iterload('test.nc', 'step5_input.parm7')
pt.write_traj('WAT.nc', traj(mask=':WAT'))
pt.write_traj('AOX.nc', traj(mask=':AOX'))
quit()

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


if [ ! -f ../../${PIPNAME}.parm7 ]
    then echo "ERROR PIPNAME"; exit
elif [ ! -f ../../Trayectoria/100ns.nc ]
    then echo "ERROR Trayectoria"; exit
fi


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

echo -e "parm ../../${1}.parm7 \ntrajin ../../Trayectoria/${10} \nautoimage" >> "$6"
echo -e "center :1-${TER[0]}\ncenter :1-${TER[1]}\ncenter :1-${TER[2]}\ncenter :1-${TER[3]}\nimage center familiar" >> "$6"
echo "strip \"!(:${7} | :${8}&@CA)\"" >> "$6"
echo "trajout ${9}" >> "$6"
echo -e "run \n clear all" >> "$6"
}


CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_PDBS" "AOX&@O1" ${RESIDUOS_A} "AOX_CA.pdb" "100ns.nc 1 1"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_PDBS" "AOX&@O1" ${RESIDUOS_C} "AOX_CC.pdb" "100ns.nc 1 1"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_PDBS" "WAT&@O" ${RESIDUOS_A} "H2O_CA.pdb" "100ns.nc 1 1"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_PDBS" "WAT&@O" ${RESIDUOS_C} "H2O_CC.pdb" "100ns.nc 1 1"


CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_NCS" "AOX&@O1" ${RESIDUOS_A} "AOX_CA.nc" "[0-5]00ns.nc"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_NCS" "AOX&@O1" ${RESIDUOS_C} "AOX_CC.nc" "[0-5]00ns.nc"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_NCS" "WAT&@O" ${RESIDUOS_A} "H2O_CA.nc" "[0-5]00ns.nc"
CP_INPUT $PIPNAME "${TER[@]}" "$CPPFILE_NCS" "WAT&@O" ${RESIDUOS_C} "H2O_CC.nc" "[0-5]00ns.nc"


echo -e "\n exit" >> "$CPPFILE_NCS"; echo -e "\n exit" >> "$CPPFILE_PDBS";

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
