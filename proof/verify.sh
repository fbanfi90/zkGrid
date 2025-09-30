#!/bin/bash
set -Eeuo pipefail

# INPUT: vkey.json, public.json, proof.json 

# Setting
OUT=output

# Verify proof
if snarkjs groth16 verify $OUT/vkey.json $OUT/public.json $OUT/proof.json >/dev/null 2>&1; then
    echo -e "\033[0;32mACCEPTED\033[0m"
else 
    echo -e "\033[0;31mREJECTED\033[0m"
fi
