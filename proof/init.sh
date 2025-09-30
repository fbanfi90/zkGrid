#!/bin/bash
set -Eeuo pipefail

# INPUT: lsbcheck.circom
# OUTPUT: lsbcheck.zkey, vkey.json, lsbcheckjs/*

# Settings
IN=input
OUT=output
TMP=tmp

# Setup
mkdir -p $OUT $TMP

# Generate randomness
RAND1=$(head -c 256 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)
RAND2=$(head -c 256 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)

# Phase 1
snarkjs powersoftau new bn128 12 $TMP/0.ptau -v
echo $RAND1 | snarkjs powersoftau contribute $TMP/0.ptau $TMP/1.ptau --name="Phase 1" -v

# Process circuit
git clone https://github.com/iden3/circomlib.git $IN/circomlib
circom $IN/lsbcheck.circom --r1cs --wasm -l $IN/circomlib/circuit -o $OUT

# Phase 2
snarkjs powersoftau prepare phase2 $TMP/1.ptau $TMP/2.ptau -v
snarkjs groth16 setup $OUT/lsbcheck.r1cs $TMP/2.ptau $TMP/0.zkey
echo $RAND2 | snarkjs zkey contribute $TMP/0.zkey $OUT/lsbcheck.zkey --name="Phase 2" -v
snarkjs zkey export verificationkey $OUT/lsbcheck.zkey $OUT/vkey.json

# Clean-up
rm -rf $TMP
