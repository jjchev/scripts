declare -A CHAIN
CHAIN[A]="1-285"
CHAIN[B]="286-570"
CHAIN[C]="571-855"
CHAIN[D]="856-1140"


for i in "${!CHAIN[@]}"; do
echo -e "parm ../../Mt23_O_500.parm7 \n trajin ../../Trayectoria/[0-5]00ns.nc 1 last 10" >> ${i}.in
echo -e "strip @*&!:${CHAIN[$i]}@CA,C,O,N,H \ntrajout tolovo${i}.pdb \nrun\nexit" >> ${i}.in
done

(echo cpptraj -i A.in; echo cpptraj -i B.in; echo cpptraj -i C.in; echo cpptraj -i D.in) | parallel &

wait $!

for i in "${!CHAIN[@]}"; do

(echo "mdlovofit -f 0.8 -rmsf rmsf${i}.dat -t alig${i}.pdb tolovo${i}.pdb > rmsd${i}80.dat") | parallel & 

done
