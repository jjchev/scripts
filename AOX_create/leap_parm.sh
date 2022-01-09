#! /bin/bash
read -p 'BOX? (format xxx.x xxx.x xxx.x)' BOX_DIMENSIONS

tar xvf Inputs.tar.xz

PIP="Zm12_Zm25_500"
INPUT_LEAP=$(mktemp)
INPUT_PARMED=$(mktemp)
INPUT_CPP=$(mktemp)

pdb4amber -i post_change.pdb -o toleap.pdb
wait
rm toleap_* 2>/dev/null

sed "s/XXXX/${PIP}/g" < aox.leapfile | sed "s/YYYY/${PIP}/g" | sed "s/XBOXX/${BOX_DIMENSIONS}/g" >> ${INPUT_LEAP}
tleap -f ${INPUT_LEAP}
wait


sed "s/XXXX/${PIP}_woHMR/g" < ParmInput | sed "s/YYYY/${PIP}/g" >> ${INPUT_PARMED}
parmed -i ${INPUT_PARMED}
wait

echo -e "parm ${PIP}.parm7 \n trajin ${PIP}.rst7 \n autoimage" >> $INPUT_CPP
grep OXT < ${PIP}.pdb| awk '{print $5}' | xargs -I {} echo "center :1-{}" >> $INPUT_CPP
echo -e "image center familiar \n trajout ${PIP}.rst7 \n run" >> $INPUT_CPP
echo -e "clear all \n parm ${PIP}.parm7 \n trajin ${PIP}.rst7 \n trajout revisar.pdb \n run \n exit" >> $INPUT_CPP

cpptraj -i $INPUT_CPP
wait

rm aox.leapfile AOX.in AOX.prm ParmInput parmAOX.lib 2>/dev/null



for i in $(seq 1 4);
do
sleep 3
spd-say "Proceso Finalizado"
done


exit
