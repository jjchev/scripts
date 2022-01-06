#!/bin/bash


for i in *.mdin
do
        [[ -e "$i" ]] || break
        FILE=$(mktemp)
        FILE2=$(mktemp)
        grep -vE "csurften|gamma_ten|ninterface" < "$i"| sed 's/ntp=./ntp=2/g' > "$FILE2" && mv "$FILE2" "$FILE"

        if [ "$i" == "step6.0_minimization.mdin" ] ; then
               grep -v "&end" < "$FILE" > "$FILE2" && mv "$FILE2" "$FILE"

        elif [ "$i" == "step7_production.mdin" ] ; then
                sed 's/nstlim=250000/nstlim=500000/g' < "$FILE"| sed 's/ntwx=25000/ntwx=5000/g' > "$FILE2" && mv "$FILE2" "$FILE"
        fi

rm "$i"
cat "$FILE" >> "${i}"

done



amber="pmemd.cuda"
init="step5_input"
istep="step6.0_minimization"

# Minimizacion

if [ -e dihe.restraint ]; then sed -e "s/FC/250.0/g" dihe.restraint > ${istep}.rest; fi
mpirun --use-hwthread-cpus -np 16 sander.MPI -O -i ${istep}.mdin -p ${init}.parm7 -c ${init}.rst7 -o ${istep}.mdout -r ${istep}.rst7 -inf ${istep}.mdinfo -ref ${init}.rst7

# Equilibration

cnt=1
cntmax=6
fc=('250.0' '100.0' '50.0' '50.0' '25.0')


while [ ${cnt} -le ${cntmax} ]
do
   (( pcnt = cnt - 1 ))

   if [ ${cnt} == 1 ]; then
           pstep="step6.${pcnt}_minimization"
           istep="step6.${cnt}_equilibration"
   else
           pstep="step6.${pcnt}_equilibration"
           istep="step6.${cnt}_equilibration"
   fi

   if [ -e dihe.restraint ] && [ ${cnt} \< ${cntmax} ]; then  sed -e "s/FC/${fc[${cnt}]}/g" dihe.restraint > ${istep}.rest ; fi

   pmemd.cuda -O -i ${istep}.mdin -p ${init}.parm7 -c ${pstep}.rst7 -o ${istep}.mdout -r ${istep}.rst7 -inf ${istep}.mdinfo -ref ${init}.rst7 -x ${istep}.nc
   (( cnt=++cnt ))
done

#  Production

cnt=1
cntmax=500
input="step7_production"

while [ ${cnt} -le ${cntmax} ]
do
    (( pcnt = cnt - 1 ))
    if [ ${cnt} == 1 ]; then
            pstep="step6.6_equilibration"
            istep="step7_${cnt}"
    else
            pstep="step7_${pcnt}"
            istep="step7_${cnt}"
    fi
    ${amber} -O -i ${input}.mdin -p ${init}.parm7 -c ${pstep}.rst7 -o ${istep}.mdout -r ${istep}.rst7 -inf ${istep}.mdinfo -x ${istep}.nc
    (( cnt += 1 ))
done
