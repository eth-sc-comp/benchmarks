# Ethereum Smart Contract Benchmarks

This repository contains a set of bechmarks that are intended to provide some kind of objective
measurements for the strengths and weaknesses of various analysis tooling targeting ethereum smart
contracts. In practice this means tools that consume Solidity, Yul, or EVM bytecode.

The benchmarks in this repo should be useful to developers of all kinds of tools, including fuzzers,
static analyzers, and symbolic execution engines.

In order to make interoperabilty as easy as possible we define standard formats for both benchmarks
and counterexamples (to allow for the detection of false positives with an external reference tool).

## Using This Repository

We use nix to provide a zero overhead reproducable environment that contains all tools required to
run the benchmarks. if you want to add a new tool then you need to extend the `flake.nix` so that
this tool is present in the `devShell`.

To enter the envrionment, run `nix develop`, and then run `python bench.py` to execute the
benchmarks. This will write the results of the benchmarks to a `results.json` file with the
following format:

```json
{
  "tool_name": {
    "solidity_file": {
      "contract_name": <time_taken>
    }
  }
}
```

## Formats

### Benchmarks

Benchmarks are defined as solidity contracts containing calls to `assert`. The tools should take the
contract as an input, and declare the contract as either safe or unsafe.

```sol
contract C {
    function f() public {
      assert(false);
    }
}
```

### Harnesses

In order to include a tool in this repository, you should add a script for that tool under `tools/<tool_name>.sh`.

This script should have the signature: `tools/SCRIPT_NAME <contract_file> <contract_name>`.

It should output a single `1` to stdout for unsafe contracts and a `0` for safe contracts.

Before executing the benchmarks, `forge build` is invoked on all solidity files in the repo, and
tools that operate on evm bytecode can read the compiled bytecode directly from the forge build
outputs.

In the future we aim to extend the returned information with a common format for counterexamples
that can be validated against some reference evm implementation (e.g. geth).
