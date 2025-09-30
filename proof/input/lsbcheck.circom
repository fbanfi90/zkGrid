pragma circom 2.2.2;

include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/bitify.circom";

template LSBCheck() {

    // === Inputs ===
    signal input s; // 128-bit seed
    signal input i; // 4-bit i coordinate 
    signal input j; // 4-bit j coordinate

    // === Constrain inputs bit lengths ===
    component sBits = Num2Bits(128);
    sBits.in <== s;
    component iBits = Num2Bits(4);
    iBits.in <== i;
    component jBits = Num2Bits(4);
    jBits.in <== j;

    // === Compute Poseidon hash of inputs ===
    component poseidon = Poseidon(3);
    poseidon.inputs[0] <== s; 
    poseidon.inputs[1] <== i;
    poseidon.inputs[2] <== j;

    // === Decompose hash output ===
    component hashBits = Num2Bits(254);
    hashBits.in <== poseidon.out;

    // === Constrain lowest 8 bits of hash to be 0 ===
    for (var k = 0; k < 8; k++) {
        hashBits.out[k] === 0;
  }
}

component main = LSBCheck();
