#!/usr/bin/env python3

import subprocess
from pathlib import Path
import time
import copy
import json
from typing import Dict, Tuple, Any, Literal
import optparse

SOLC_VERSION = "0.8.19"
tools = {"hevm": "tools/hevm.sh"}
global opts

def verb_print(*arg):
    if opts.verbose:
        print(*arg)

def printable_output(out):
    return ("%s" % out).replace('\\n', '\n').replace('\\t', '\t')

def build_contracts() -> None:
    ret = subprocess.run(["forge", "build", "--use", SOLC_VERSION], capture_output=True)
    print(printable_output(ret.stdout))
    if ret.returncode != 0:
        print("Forge returned error(s)")
        print(printable_output(ret.stderr))
        exit(-1)

    ret.check_returncode()


def get_prove_funcs(js) -> list[str]:
    ret = []
    for i in range(len(js["abi"])):
        if "name" not in js["abi"][i]: continue
        fun = js["abi"][i]["name"]
        if "prove" in fun: ret.append(fun)

    return ret

# determines whether dstest or not
def determine_dstest(sol_file: str) -> bool:
    if sol_file.startswith("src/safe/ds-test") or sol_file.startswith("src/unsafe/ds-test"):
        return True
    elif sol_file.startswith("src/safe/1tx-abstract") or sol_file.startswith("src/unsafe/1tx-abstract"):
        return False
    else:
        raise ValueError(
            "solidity file is neither in 'ds-test' nor in '1tx-abstract' directory: " + sol_file
        )

# determines whether or not a given test case is expected to be safe or unsafe
def determine_expected(sol_file: str) -> Literal["safe"] | Literal["unsafe"]:
    if sol_file.startswith("src/safe"):
        return "safe"
    elif sol_file.startswith("src/unsafe"):
        return "unsafe"
    else:
        raise ValueError(
            "solidity file is not in the safe or unsafe directories: " + sol_file
        )


class Case:
    def __init__(self, contract: str, json_fname: str, sol_file: str, ds: bool, fun: str):
        self.contract = contract
        self.json_fname = json_fname
        self.sol_file = sol_file
        self.ds = ds
        self.fun = fun
        self.expected = determine_expected(sol_file)
    def __str__(self):
        out = ""
        out+="Contract: %s, " % self.contract
        out+="Function: %s, " % self.fun
        out+="JSON filename: %s, " % self.json_fname
        out+="Is DS?: %s, " % self.ds
        out+="Expected result: %s" % self.expected
        return out


# builds a mapping from solidity files to lists of contracts. we do this by
# parsing the foundry build output, since that's easier than parsing the actual
# solidity code to handle the case where a single solidity file contains
# multiple contracts
def gather_cases() -> list[Case]:
    # build a dictionary where the key is a directory in the foundry build
    # output, and the value is a list of contract names defined within
    output_jsons = {
        str(f): [j.stem for j in f.glob("*.json")]
        for f in Path("./out").iterdir()
        if f.is_dir()
    }

    # replace the path to the output json with the path to the original solidity file
    cases: list[Case] = []
    for out_dir, contracts in output_jsons.items():
        for c in contracts:
            json_fname = f"{out_dir}/{c}.json"
            with open(json_fname) as oj:
                js = json.load(oj)
                sol_file: str = js["ast"]["absolutePath"]
                if sol_file.startswith("lib/"): continue
                ds_test = determine_dstest(sol_file)
                if ds_test:
                    for f in get_prove_funcs(js):
                        cases.append(Case(c, json_fname, sol_file, True, f))
                else:
                    cases.append(Case(c, json_fname, sol_file, False, ""))
    return cases


# executes the given tool script against the given test case and returns the
# time taken and the reported result
def execute_contract(tool: str, case: Case) -> Tuple[int, str]:
    time_taken = None
    result = None
    res = None
    before: int = time.time_ns()
    toexec = [tool, case.sol_file, case.contract, case.fun, "%i" % case.ds]
    print("To re-run, execute: %s" % (" ".join(toexec)))
    try:
        res = subprocess.run(
            toexec,
            capture_output=True,
            encoding="utf-8",
            timeout=opts.timeout,
        )
    except subprocess.TimeoutExpired:
        result = "unknown"
        time_taken = opts.timeout*2
    else:
        after: int = time.time_ns()
        lines = res.stderr.split("\\n")
        result = res.stdout.rstrip()
        time_taken = (after - before) // 1_000_000
        verb_print("Lines is: ", "\n".join(lines))
        verb_print("Result is: '%s'" % result)

    assert result == "safe" or result == "unsafe" or result == "unknown"
    return (time_taken, result)

class Result :
    def __init__(self, result: str, t: float, case: Case) :
        self.result = result
        self.t = t
        self.case = case

# executes all tests contained in the argument cases mapping with all tools and
# builds the result dict
def run_all_tests(cases: list[Case]) -> dict[str, list[Result]]:
    # execute each tool on each testcase and write the execution times to a
    # dictionary (tool -> file -> contract -> (expected, result, time_taken))
    results: dict[str, list[Result]] = {}
    for tool, script in tools.items():
        res = []
        for c in cases:
            (time, result) = execute_contract(script, c)
            res.append(Result(result, time, c))
        results[tool] = res
    return results


# --- main ---


def set_up_parser():
    usage = "usage: %prog [options]"
    desc = """Run all benchmarks for all tools
    """

    parser = optparse.OptionParser(usage=usage, description=desc)
    parser.add_option("--verb", "-v", action="store_true", default=False,
                      dest="verbose", help="More verbose output. Default: %default")

    parser.add_option("-s", dest="seed", type=int, default=1,
                      help="Seed for random numbers for reproducibility. Default: %default")

    parser.add_option("-t", dest="timeout", type=int, default=25,
                      help="Max time to run. Default: %default")

    return parser

def main() -> None:
    parser = set_up_parser()
    global opts
    (opts, args) = parser.parse_args()
    if len(args) > 0:
        print("Benchmarking does not accept arguments")
        exit(-1)

    build_contracts()
    cases = gather_cases()
    print("cases gathered: ")
    for c in cases: print("-> %s" % c)
    results = run_all_tests(cases)
    with open("results.json", "w") as res:
        res.write(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
