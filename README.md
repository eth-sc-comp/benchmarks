# Ethereum Smart Contract Analysis Benchmarking

This repository contains a set of benchmarks, a bench harness, and graph
generation utilities that are intended to provide some kind of objective
measurements for the strengths and weaknesses of various analysis
tooling targeting Ethereum smart contracts. In practice this means tools that
consume Solidity, Yul, or EVM bytecode.

The benchmarks in this repo should be useful to developers of all kinds of
tools, including fuzzers, static analyzers, and symbolic execution engines.

### Quick Start Guide -- Linux

Install nix (see [here](https://nixos.org/download.html)). Then:

```
# optional, but will make subsequent steps significantly faster
nix-shell -p cachix --command "cachix use k-framework"

nix develop   # this may take some time
./bench.py
./gen_graphs.py
cd graphs
```

You can look at the graphs under the folder `graphs`

### Quick Start Guide -- Mac

You will need to create a docker image. This is because unfortunately MacOS
does not support the procfs (i.e. `/proc`) and `runlim` does not work with
`sysctl`. We suggest the following setup:

```
brew install colima
colima start
docker ps -a
```

If `docker ps -a` ran fine, then you can now create a docker image via:

```
docker build --tag sym-bench .
docker run -it --rm sym-bench
./bench.py
./gen_graphs.py
```

## Using This Repository

We use Nix to provide a zero overhead reproducible environment that contains
all tools required to run the benchmarks. If you want to add a new tool then
you need to extend the `flake.nix` so that this tool is present in the
`devShell`.

To enter the environment, run `nix develop`. Once you have a working shell, you
can run `python bench.py` to execute the benchmarks. The results are collected
in `results.db` sqlite3 database and the csv and json files
`results-[timestamp].csv/json`. You can view these files using standard tools
such as libreoffice, Excel, jq, etc.

To generate graphs, run `python gen_graph.py`.  Then, you can
look at the cumulative distribution function (CDF) graph to get an overview.
Here, the different tools' performances are displayed, with X axis showing
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

There are two types of benchmarks. The ones under `src/safe/1tx-abstract` and
under `src/unsafe/1tx-abstract` are standard Solidity contracts that have all
their functions checked to have triggerable assert statements. For these files,
either the entire contract is deemed safe or unsafe. The files under
`src/safe/ds-test` and under `src/unsafe/ds-test` are tested differently. Here,
only functions starting with the `prove` keyword are tested, individually,
for safety. Hence, each function may be individually deemed safe/unsafe. Contracts
under these directories can use the full set of foundry
[cheatcodes](https://book.getfoundry.sh/cheatcodes/) and assertion helpers.

An example `1tx` benchmark is below. It would be under
`src/unsafe/1tx-abstract` since the `assert` can be triggered with `x=10`.

```sol
contract C {
    function f(uint256 x) public {
      assert(x != 10);
    }
}
```


An example `ds-test` benchmark is below. It would be under
`src/unsafe/ds-test` since the `assert` can be triggered with `x=11`.

```sol
contract C {
    function prove_f(uint256 x) public {
      assert(x != 11);
    }
}
```

## Execution Environments

Currently, there is a global 25 second wall clock timeout applied to all tool
invocations. This is adjustable with the `-t` option to `bench.py`. Tools that
take longer than this to produce a result for a benchmark will have an
"unknown" result assigned. There is currently no memory limit enforced.

Each tool is allowed to use as many threads as it wishes, typically
auto-detected by each tool to be the number of cores in the system. This means
that the execution environment may have an impact on the results. Tools that
are e.g. single-threaded may seem to perform better in environments with few
cores, while the reverse may be the case for tools with a high level of
parallelism and an execution environment with 128+ cores.

## Adding a New Tool

In order to include a tool in this repository, you should add a script for that
tool under `tools/<tool_name>.sh`. You will also need to add a script
`tools/<tool_name>_version.sh`. Then, add a line to `bench.py` that explains to
the script how your tool is used.

Your main shell script should output:

- "safe": if the contract contains no reachable assertion violations
- "unsafe": if the contract contains at least one reachable assertion violation
- "unknown": if the tool was unable to determine whether a reachable assertion violation is present

Before executing the benchmarks, `forge build` is invoked on all Solidity files
in the repository, and tools that operate on EVM bytecode can read the compiled
bytecode directly from the respective build outputs.

Check out the examples for `hevm` and `halmos` in the repository for examples.
Note that in order for others to run your tool, it needs to be added to
`flake.nix`.

## Categories

- conformance: should be easy, test correctness only
- performance: should be hard

[ ] loops
[ ] calls
[x] constructors
[x] arithmetic
[x] bitwise
[ ] cheatcodes
[x] memory
[x] storage
[x] keccak
[x] calldata
[ ] returndata
[ ] address modeling

- real world:
  [x] erc20
  [x] erc721
  [x] deposit
  [x] amm
