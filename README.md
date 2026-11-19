# zkGrid

This puzzle game uses [zk-SNARKs](https://en.wikipedia.org/wiki/ZkSNARK) to enable you to prove in [zero-knowledge](https://en.wikipedia.org/wiki/Zero-knowledge_proof) that you found the empty cell in a dotted grid, that is, without revealing its location. The proof is generated with [Circom](https://docs.circom.io/) and [snarkjs](https://github.com/iden3/snarkjs) using the [Groth16](https://eprint.iacr.org/2016/260) proving system and is displayed as a QR code. Open the app on another device and select **Verify** to validate QR proofs. Zero-knowledge guarantees that the data in the QR code contains no information about the empty cell location.

## How it works

The server ([server.js](server.js)) picks a random 128-bit seed `s` and computes `h = Poseidon(s, i, j)` for every cell `(i, j)` of a 16×16 grid. The lowest byte of `h` sets where the dot sits inside the cell. A cell whose lowest byte is `0` has no visible dot. The server keeps drawing seeds until exactly one such cell exists, then sends the seed and the grid to the browser.

When you tap the empty cell, the browser ([public/index.html](public/index.html)) runs the circuit and produces a Groth16 proof. The seed `s` is a public input, and the cell `(i, j)` stays private. The QR code holds the proof and `s`. Below the grid, the app shows the puzzle's code: the full seed in hex. After a valid proof, the verifier shows the code of the seed the proof was checked against. If the two codes match, the proof is for that exact puzzle. The whole code must match: a cheater can freely choose a seed that shares part of it. Anyone holding the seed could compute the empty cell in code; the proof itself reveals nothing more. The circuit ([proof/input/lsbcheck.circom](proof/input/lsbcheck.circom)) checks that:

- `s` fits in 128 bits, and `i` and `j` fit in 4 bits each;
- the lowest 8 bits of `Poseidon(s, i, j)` are zero.

The hash is split into bits with `Num2Bits_strict`, which ensures there is only one valid bit pattern (see [Circuit check](#circuit-check)).

## Proof pipeline

The [proof/](proof/) folder rebuilds the files the app serves from `public/`. Run the scripts from inside `proof/` with bash (Linux, macOS or WSL). They need `node`/`npx`, `git` and `curl`. circom (v2.2.2) and snarkjs (v0.7.5) are pinned and fetched locally, so nothing is installed system-wide.

| Script | What it does |
|---|---|
| `init.sh` | Compiles the circuit and runs a fresh Groth16 trusted setup. Writes `lsbcheck.wasm`, `lsbcheck.zkey` and `vkey.json` to `output/`. |
| `generate.sh` | Creates a proof for `input/input.json`. |
| `verify.sh` | Verifies that proof against `vkey.json`. |
| `check.sh` | Runs the [circomspect](https://github.com/trailofbits/circomspect) static analyzer on the circuit. Requires `cargo`. |
| `clean.sh` | Deletes everything the scripts generated. |

`lsbcheck.wasm` is reproducible. The zkey and vkey are not: they depend on random setup contributions, so each run of `init.sh` gives new keys. To deploy, copy all three files from the same run into `public/`. Proofs made with the old keys will no longer verify.

## Circuit check

`check.sh` caught a soundness bug in an earlier version of the circuit, which used `Num2Bits(254)` on the hash. The BN254 field prime `p` is smaller than `2^254`. So for some hashes, `h + p` also fits in 254 bits, and a prover could submit its bits instead of the bits of `h`. Because `p ≡ 1 (mod 256)`, a cell whose hash ends in `0xFF` could then pass as empty. `Num2Bits_strict` adds an alias check that requires the bits to encode a value below `p`.
