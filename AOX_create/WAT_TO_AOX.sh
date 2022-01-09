#!/bin/bash

RESIDS=$(shuf -i 3561-92063 -n 500 | tr '\n' ',' | sed 's/,$//g')
cat <<EOF >> IMPUT

parm step5*.parm7
trajin step7*.rst7
autoimage
center :1-285
center :1-574
center :1-863
center :1-1148
image center familiar
trajout pre_change.pdb
run
clear all
parm step5*.parm7
trajin step7*.rst7
autoimage
center :1-285
center :1-574
center :1-863
center :1-1148
image center familiar
strip :${RESIDS}@H1,H2
change atomname from :${RESIDS}@O to O1
change resname from :${RESIDS} to AOX
trajout post_change.pdb
run
exit

EOF

cpptraj -i IMPUT 2>/dev/null &
wait $!

NUMWAT_PRE=$(cat pre_change.pdb | grep WAT | grep H1 | wc -l)
NUMWAT_POST=$(cat post_change.pdb | grep WAT | grep H1 | wc -l)
NUMAOX=$(cat post_change.pdb | grep AOX | grep O1 | wc -l)
BOX=$(cat step5*.parm7 | grep -n2 BOX | tail -n 1)
echo "#####################################$(date)###############################################"
echo "Agregados $NUMAOX Peroxidos en el PDB. Numero de aguas= ${NUMWAT_POST} (Previas ${NUMWAT_PRE}), ratio=1/$(( NUMWAT_POST / NUMAOX))"
echo "BOX - $BOX"
