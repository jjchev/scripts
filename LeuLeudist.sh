#!/bin/bash

TER=($(cat Cadenas.pdb | egrep "TER"  | awk '{print $4}'))
declare -A CHAIN
CHAIN[A]="1-${TER[0]}"
CHAIN[B]="$((${TER[0]} + 1 ))-${TER[1]}"
CHAIN[C]="$((${TER[1]} + 1 ))-${TER[2]}"
CHAIN[D]="$((${TER[2]} + 1 ))-${TER[3]}"


for i in "${!CHAIN[@]}"; do
echo -e "parm alig${i}.pdb \n trajin alig${i}.pdb" >> ${i}.in

echo -e "distance :114 :203 out LL${i}.dat \n run \n exit" >> ${i}.in
done

(echo cpptraj -i A.in; echo cpptraj -i B.in; echo cpptraj -i C.in; echo cpptraj -i D.in) | parallel &

exit
