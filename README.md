# Ethereum Smart Contract Symbolic Execution Benchmarking

This repository contains a set of benchmarks, a bench harness, and graph
generation utilities that are intended to provide some kind of objective
measurements for the strengths and weaknesses of various static analysis
tooling targeting Ethereum smart contracts. In practice this means tools that
consume Solidity, Yul, or EVM bytecode.

The benchmarks in this repo should be useful to developers of all kinds of
tools, including fuzzers, static analyzers, and symbolic execution engines.

In order to make interoperability as easy as possible we define standard
formats for both benchmarks and counterexamples (to allow for the detection of
false positives with an external reference tool).

## Using This Repository

We use Nix to provide a zero overhead reproducible environment that contains
all tools required to run the benchmarks. If you want to add a new tool then
you need to extend the `flake.nix` so that this tool is present in the
`devShell`.

To enter the environment, run `nix develop`, and then run `python bench.py` to
execute the benchmarks. The results are collected in `results.db` sqlite3
database and the csv and json files `results-[timestamp].csv/json`.

To generate graphs, run `python gen_graph.py`. Results. For example, you can
look at the cumulative distribution function (CDF) graph to get an overview.
Here, the different tools's performances are displayed, with X axis showing
time, and the Y axis showing the number of problems solved within that time
frame. Typically, a tool is be better when it solves more instances (i.e.
higher on the Y axis) while being faster (i.e. more to the left on the X axis)

The system also generates one-on-one comparisons for all tested tools, and
a box chart of all tools' performance on all instances.

## Adding a New Benchmark

First, a note on benchmark selection. It is important to keep in mind that the
set of benchmarks the tools are evaluated on significantly impacts which tool
"looks" best on e.g. the CDF plot. For fairness, we strongly recommend contract
authors to add interesting problems via pull requests. A problem can be
interesting because e.g. it's often needed but generally slow to solve, or
because some or even all tools could not solve it. This can help drive
development of tools and ensure more fairness in the comparisons.

Benchmarks are defined as Solidity contracts containing calls to `assert`.
Contracts that do not contain reachable assertion violations are contained
within the `src/safe` directory, and those that do are contained within
`src/unsafe`.

An example benchmark:

```sol
contract C {
    function f() public {
      assert(false);
    }
}
```

There is a global 25 second timeout applied to all tool invocations, and tools that take longer than
this to produce a result will have an "unknown" result assigned for that benchmark.

## Adding a New Tool

In order to include a tool in this repository, you should add a script for that
tool under `tools/<tool_name>.sh`. You will also need to add a script
`tools/<tool_name>_version.sh`. Then, add a line to `bench.py` that explains to
the script how your tool is used.

Your main shell script should output:

- "safe": if the contract contains no reachable assertion violations
- "unsafe": if the contract contains at least one reachable assertion violation
- "unknown": if the tool was unable to determine whether a reachable assertion violation is present

Before executing the benchmarks, either `forge build` or python crytic compile
(configurable in bench.py) is invoked on all Solidity files in the repository,
and tools that operate on EVM bytecode can read the compiled bytecode directly
from the respective build outputs.

Check out the examples for `hevm` and `halmos` in the repository for examples.
Note that in order for others to run your tool with the same easy-of-use, it
needs to be added to `flake.nix`.
