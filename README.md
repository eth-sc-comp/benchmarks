**UNDER CONSTRUCTION**

- `benchmarks/`: Tests to benchmarks tools against.
  - `basic/`: Hand-written simple tests.
- `tools/`: Scripts to run tools.

The scripts in `tools/` must:

- Have the signature `tools/SCRIPT_NAME <contract_file> <contract_name>`.
- Output a list of reachable `assert(...)` statements.
- Output a list of unreachable `assert(...)` statements.
- Output a list of unknown `assert(...)` statements.

Example thing to do:

```sh
nix develop
./tools/test-kevm.sh benchmarks/basic/assert-false.sol AssertFalse
```
