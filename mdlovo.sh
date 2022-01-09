#! /bin/bash

PDB=$(mktemp)
echo -e "parm ../../Mt23_O_500.parm7 \n trajin ../../Trayectoria/100ns.nc 1 1 \n trajout Cadenas.pdb \n run \n exit" >> ${PDB}
cpptraj -i ${PDB} && wait
TER=($(cat Cadenas.pdb | egrep "TER"  | awk '{print $4}'))

declare -A CHAIN
CHAIN[A]="1-${TER[0]}"
CHAIN[B]="$((${TER[0]} + 1 ))-${TER[1]}"
CHAIN[C]="$((${TER[1]} + 1 ))-${TER[2]}"
CHAIN[D]="$((${TER[2]} + 1 ))-${TER[3]}"

for i in "${!CHAIN[@]}"; do
echo -e "parm ../../Mt23_O_500.parm7 \n trajin ../../Trayectoria/[0-5]00ns.nc 1 last 10" >> ${i}.in
echo -e "strip @*&!:${CHAIN[$i]}@CA,C,O,N,H \ntrajout tolovo${i}.pdb \nrun\nexit" >> ${i}.in
done

(echo cpptraj -i A.in; echo cpptraj -i B.in; echo cpptraj -i C.in; echo cpptraj -i D.in) | parallel &

wait $!

for i in "${!CHAIN[@]}"; do

(echo "mdlovofit -f 0.8 -rmsf rmsf${i}.dat -t alig${i}.pdb tolovo${i}.pdb > rmsd${i}80.dat") | parallel & 

done
