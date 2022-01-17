#! /bin/bash
shopt -s lastpipe

PIPNAME="At28O_3K"
CPPFILE_CHAINS=$(mktemp)
CPPFILE_PDBS=$(mktemp)
CPPFILE_NCS=$(mktemp)

cat << EOF > "${CPPFILE_CHAINS}"
parm ../../${PIPNAME}.parm7
trajin ../../Trayectoria/100ns.nc 1 1
trajout Cadenas.pdb
EOF
cpptraj -i "${CPPFILE_CHAINS}"

TER=()
grep -E "TER"  < Cadenas.pdb | awk '{print $4}' | while IFS="" read -r line; do TER+=("$line"); done

rm Cadenas.pd
sed -E "s/XXXX/1-${TER[0]}\ncenter :1-${TER[1]}\ncenter :1-${TER[2]}\ncenter :1-${TER[3]}/g" < PDB_anyname.cpptraj >> "${CPPFILE_PDBS}"
sed -E "s/XXXX/1-${TER[0]}\ncenter :1-${TER[1]}\ncenter :1-${TER[2]}\ncenter :1-${TER[3]}/g" < anyname.cpptraj >> "${CPPFILE_NCS}"
cpptraj -i "${CPPFILE_PDBS}"
mpirun --use-hwthread-cpus -np 16 cpptraj.MPI -i "${CPPFILE_NCS}"
