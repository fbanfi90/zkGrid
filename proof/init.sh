#!/bin/bash
set -Eeuo pipefail

# INPUT: lsbcheck.circom
# OUTPUT: lsbcheck.wasm, lsbcheck.zkey, vkey.json (served from public/), lsbcheck_js/*

# Settings
IN=input
CIRCOMLIB_VERSION=v2.0.5
OUT=output
TMP=tmp
SNARKJS="npx --yes snarkjs@0.7.5"
CIRCOM_VERSION=v2.2.2
CIRCOM=bin/circom

# Setup
mkdir -p $OUT $TMP

# Generate randomness
RAND1=$(head -c 256 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)
RAND2=$(head -c 256 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)

# Phase 1
$SNARKJS powersoftau new bn128 12 $TMP/0.ptau -v
echo $RAND1 | $SNARKJS powersoftau contribute $TMP/0.ptau $TMP/1.ptau --name="Phase 1" -v

# Get circom (pinned prebuilt Linux binary, kept local to this folder)
if [ ! -x $CIRCOM ]; then
    mkdir -p bin
    curl -fL -o $CIRCOM https://github.com/iden3/circom/releases/download/$CIRCOM_VERSION/circom-linux-amd64
    chmod +x $CIRCOM
fi

# Process circuit
[ -d $IN/circomlib ] || git -c advice.detachedHead=false clone --depth 1 --branch $CIRCOMLIB_VERSION https://github.com/iden3/circomlib.git $IN/circomlib
$CIRCOM $IN/lsbcheck.circom --r1cs --wasm -l $IN -o $OUT
cp $OUT/lsbcheck_js/lsbcheck.wasm $OUT/lsbcheck.wasm

# Phase 2
$SNARKJS powersoftau prepare phase2 $TMP/1.ptau $TMP/2.ptau -v
$SNARKJS groth16 setup $OUT/lsbcheck.r1cs $TMP/2.ptau $TMP/0.zkey
echo $RAND2 | $SNARKJS zkey contribute $TMP/0.zkey $OUT/lsbcheck.zkey --name="Phase 2" -v
$SNARKJS zkey export verificationkey $OUT/lsbcheck.zkey $OUT/vkey.json

# Clean-up
rm -rf $TMP
