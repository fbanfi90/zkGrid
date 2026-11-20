#!/bin/bash
set -Eeuo pipefail

# INPUT: lsbcheck.circom
# OUTPUT: circomspect static analysis report (extra args are passed to circomspect, e.g. -l INFO)
# REQUIRES: cargo (https://rustup.rs), only for this script

# Settings
IN=input
CIRCOMLIB_VERSION=v2.0.5
CIRCOMSPECT_VERSION=0.9.0
CIRCOMSPECT=bin/circomspect/bin/circomspect

# Get circomspect (pinned, built locally into this folder)
if [ ! -x $CIRCOMSPECT ]; then
    if ! command -v cargo >/dev/null; then
        echo "cargo not found: install Rust from https://rustup.rs to run circomspect" >&2
        exit 1
    fi
    cargo install --locked --root bin/circomspect circomspect --version $CIRCOMSPECT_VERSION
fi

# Get circomlib
[ -d $IN/circomlib ] || git -c advice.detachedHead=false clone --depth 1 --branch $CIRCOMLIB_VERSION https://github.com/iden3/circomlib.git $IN/circomlib

# Analyze circuit
$CIRCOMSPECT -L $IN "$@" $IN/lsbcheck.circom
