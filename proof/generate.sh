#!/bin/bash
set -Eeuo pipefail

# INPUT: input.json
# OUTPUT: proof.json, public.json

# Setings
IN=input
OUT=output
TMP=tmp

# Setup
mkdir -p $TMP

# Prepare folder for nodejs
echo '{"type":"commonjs"}' > package.json

# Generate witness
if ! node $OUT/lsbcheck_js/generate_witness.js $OUT/lsbcheck_js/lsbcheck.wasm $IN/input.json $TMP/witness.wtns >/dev/null 2>&1; then
    echo -e '\033[0;31mFAILURE\033[0m'
    exit
fi

# Generate proof
if snarkjs groth16 prove $OUT/lsbcheck.zkey $TMP/witness.wtns $OUT/proof.json $OUT/public.json >/dev/null 2>&1; then
    echo -e '\033[0;32mSUCCESS\033[0m'
else
    echo -e '\033[0;31mFAILURE\033[0m'
fi 

# Clean-up
rm -rf $TMP
