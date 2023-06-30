#!/usr/bin/env python3

import subprocess
from pathlib import Path
import time
import os
import stat
import json
import re
import random
from typing import Dict, Tuple, Any, Literal
import optparse

SOLC_VERSION = "0.8.19"
tools = {"hevm": ["tools/hevm.sh", "tools/hevm_version.sh"]}
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

    def get_name(self) -> str:
        if self.ds:
            return "%s:%s:%s" % (self.sol_file, self.contract, self.fun)
        else:
            return "%s:%s" % (self.sol_file, self.contract)

    def __str__(self):
        out = ""
        out+="Contract: %s, " % self.contract
        if self.ds:
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


def unique_file(fname_begin, fname_end=".out"):
        counter = 1
        while 1:
            fname = "out/" + fname_begin + '_' + str(counter) + fname_end
            try:
                fd = os.open(
                    fname, os.O_CREAT | os.O_EXCL, stat.S_IREAD | stat.S_IWRITE)
                os.fdopen(fd).close()
                return fname
            except OSError:
                pass

            counter += 1
            if counter > 300:
                print("Cannot create unique_file, last try was: %s" % fname)
                exit(-1)

        print("ERROR: Cannot create unique temporary file")
        exit(-1)

def last_line_in_file(fname: str) -> str:
    with open(fname, 'r') as f:
        lines = f.read().splitlines()
        last_line = lines[-1]
        return last_line


class Result :
    def __init__(self, result: str, mem_used_MB: float|None, exit_status: int|None,
                 perc_CPU: int|None, t: float|None, tout: float|None, case: Case) :
        self.result = result
        self.exit_status = exit_status
        self.mem_used_MB = mem_used_MB
        self.perc_CPU = perc_CPU
        self.t = t
        self.tout = tout
        self.case = case


# executes the given tool script against the given test case and returns the
# time taken and the reported result
def execute_case(tool: str, case: Case) -> Result:
    time_taken = None
    result = None
    res = None
    before: int = time.time_ns()
    tmp_f = unique_file("output")
    tmp_f2 = unique_file("output")
    toexec = ["/usr/bin/time", "--verbose", "-o", "%s" % tmp_f2, "./runlim/runlim",
              "--real-time-limit=%s" % opts.timeout, "--output-file=%s" % tmp_f,
              tool, case.sol_file, case.contract, case.fun, "%i" % case.ds]
    print("Running: %s" % (" ".join(toexec)))
    res = subprocess.run( toexec, capture_output=True, encoding="utf-8")
    after: int = time.time_ns()
    out_of_time = False
    mem_used_MB = None
    exit_status = None
    perc_CPU = None
    with open(tmp_f, 'r') as f:
        for l in f:
            # if opts.verbose: print("runlim output line: ", l.strip())
            if re.match("^.runlim. status:.*out of time", l): out_of_time = True
    if opts.verbose: print("Res stdout is:", res.stdout)
    if opts.verbose: print("Res stderr is:", res.stderr)
    for l in res.stdout.split("\n"):
        l = l.strip()
        match = re.match("result: (.*)$", l)
        if match: result = match.group(1)
    time_taken = (after - before) / 1_000_000_000
    if out_of_time or result is None: result = "unknown"

    with open(tmp_f2, 'r') as f:
        for l in f:
            l = l.strip();
            match = re.match(r"Maximum resident set size .kbytes.: (.*)", l)
            if match: mem_used_MB = int(match.group(1))/1000

            match = re.match(r"Percent of CPU this job got: (.*)%", l)
            if match: perc_CPU = int(match.group(1))

            match = re.match(r"Exit status:[ ]*(.*)[ ]*$", l)
            if match: exit_status = int(match.group(1))

    assert result == "safe" or result == "unsafe" or result == "unknown"
    os.unlink(tmp_f)
    os.unlink(tmp_f2)
    if opts.verbose: print("Result is: ", result)

    return Result(result=result, mem_used_MB=mem_used_MB,
                  perc_CPU=perc_CPU, exit_status=exit_status,
                  t=time_taken, tout=opts.timeout, case=case)


def get_version(script: str) -> str:
    toexec = [script]
    print("Running: %s" % (" ".join(toexec)))
    res = subprocess.run( toexec, capture_output=True, encoding="utf-8")
    res.check_returncode()
    return res.stdout.rstrip()


# executes all tests contained in the argument cases mapping with all tools and
# builds the result dict
def run_all_tests(cases: list[Case]) -> dict[str, list[Result]]:
    # execute each tool on each testcase and write the execution times to a
    # dictionary (tool -> file -> contract -> (expected, result, time_taken))
    results: dict[str, list[Result]] = {}
    for tool, script in tools.items():
        version = get_version(script[1])
        res = []
        for c in cases:
            res.append(execute_case(script[0], c))
        results["%s-%s" % (tool, version)] = res
    return results


class ResultEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Result):
            solved = obj.result == "safe" or obj.result == "unsafe"
            if solved: correct = obj.result == obj.case.expected
            else: correct = None
            return {
                "name": obj.case.get_name(),
                "ds": obj.case.ds,
                "solved": solved,
                "correct":correct,
                "t": obj.t,
                "memMB": obj.mem_used_MB,
                "exit_status": obj.exit_status}
        return json.JSONEncoder.default(self, obj)


def empty_if_none(x: None|int|float) ->str:
    if x is None:
        return ""
    else: return "%s" % x


def dump_results(solvers_results: dict[str, list[Result]], fname: str):
    with open("%s.json" % fname, "w") as f:
        f.write(json.dumps(solvers_results, indent=2, cls=ResultEncoder))
    with open("%s.csv" % fname, "w") as f:
        f.write("solver,name,result,correct,t,memMB,exit_status\n")
        for solver,results in solvers_results.items():
            for r in results:
                corr_as_sqlite = ""
                if r.result is not None: corr_as_sqlite = (int)(r.result == r.case.expected)
                f.write("\"{solver}\",\"{case}\",\"{result}\",{corr},{t},{memMB},{exit_status}\n".format(
                    solver=solver, case=r.case.get_name(), result=r.result,
                    corr=corr_as_sqlite, t=empty_if_none(r.t),
                    memMB=empty_if_none(r.mem_used_MB),
                    exit_status=empty_if_none(r.exit_status)))


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

    parser.add_option("--limit", dest="limit", type=int, default=100000,
                      help="Max number of cases to run. Default: %default")

    return parser


def main() -> None:
    parser = set_up_parser()
    global opts
    (opts, args) = parser.parse_args()
    if len(args) > 0:
        print("Benchmarking does not accept arguments")
        exit(-1)

    random.seed(opts.seed)
    build_contracts()
    cases = gather_cases()
    print("cases gathered: ")
    for c in cases: print("-> %s" % c)
    random.shuffle(cases)
    solvers_results = run_all_tests(cases[:opts.limit])
    dump_results(solvers_results, "results")
    os.system("sqlite3 results.db < results.sqlite")


if __name__ == "__main__":
    main()
