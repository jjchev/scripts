#! /bin/bash
TER=($(cat $1 | egrep "TER"  | awk '{print $4}'))

echo "1-${TER[0]}, $((${TER[0]} + 1 ))-${TER[1]}, $((${TER[1]} + 1 ))-${TER[2]}, $((${TER[2]} + 1 ))-${TER[3]}"

CA_A="1-${TER[0]}"
CA_B="$((${TER[0]} + 1 ))-${TER[1]}"
CA_C="$((${TER[1]} + 1 ))-${TER[2]}"
CA_D="$((${TER[2]} + 1 ))-${TER[3]}"

# echo "$((${TER[0]} + 1 ))-${TER[1]}"
# echo "$((${TER[1]} + 1 ))-${TER[2]}"
# echo "$((${TER[2]} + 1 ))-${TER[3]}"

echo #### Pymol Chains ###
echo "alter resi $CA_A, chain=\"A\""
echo "alter resi $CA_B, chain=\"B\""
echo "alter resi $CA_C, chain=\"C\""
echo "alter resi $CA_D, chain=\"D\""
