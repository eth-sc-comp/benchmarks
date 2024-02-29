#!/usr/bin/env python3

import subprocess
from pathlib import Path
import time
import os
import stat
import json
import re
import random
from typing import Literal
import optparse
from time import gmtime, strftime
import csv


def recreate_out() -> None:
    os.system("rm -rf out")
    try:
        os.mkdir("out")
    except FileExistsError:
        pass


def build_forge() -> None:
    if not opts.norebuild:
        print("Building with forge...")
        recreate_out()
        cmd_line = ["forge", "build",
                   "--extra-output", "storageLayout", "metadata"]
        if opts.yul: cmd_line.extend(["--extra-output", "ir"])
        cmd_line.extend(["--use", opts.solc_version])
        ret = subprocess.run(cmd_line, capture_output=True)
        if ret.returncode != 0:
            print("Forge returned error(s)")
            print(printable_output(ret.stderr.decode("utf-8")))
        ret.check_returncode()

# TODO: this setup time should be reflected in the kontrol results somehow
def build_kontrol() -> None:
    if "kontrol" not in get_tools_used():
        return None
    if opts.norebuild:
        return None

    print("Building with kontrol...")
    cmd_line = ["kontrol", "build"]
    ret = subprocess.run(cmd_line, capture_output=True)
    if ret.returncode != 0:
        print("Kontrol returned error(s)")
        print(printable_output(ret.stderr.decode("utf-8")))
    ret.check_returncode()

available_tools = {
    "hevm-cvc5": {
        "call": "tools/hevm.sh",
        "version": "tools/hevm_version.sh",
        "extra_opts": ["--solver", "cvc5"],
    },
    "hevm-z3": {
        "call": "tools/hevm.sh",
        "version": "tools/hevm_version.sh",
        "extra_opts": ["--solver","z3"],
    },
    "hevm-bitwuzla": {
        "call": "tools/hevm.sh",
        "version": "tools/hevm_version.sh",
        "extra_opts": ["--solver","bitwuzla"],
    },
    "halmos": {
        "call": "tools/halmos.sh",
        "version": "tools/halmos_version.sh",
        "extra_opts": [],
    },
    "kontrol": {
        "call": "tools/kontrol.sh",
        "version": "tools/kontrol_version.sh",
        "extra_opts": [],
    }
}


global opts


# make output printable to console by replacing special characters
def printable_output(out):
    return ("%s" % out).replace('\\n', '\n').replace('\\t', '\t')


def get_signature(fun: str, inputs) -> str:
    ret = [e["internalType"] for e in inputs]

    args = ",".join(ret)
    return f"{fun}({args})"


# get all functions that start with 'prove' or 'check'
def get_relevant_funcs(js) -> list[(str,str)]:
    ret = []
    for i in range(len(js["abi"])):
        if "name" not in js["abi"][i]:
            continue
        fun = js["abi"][i]["name"]
        sig = get_signature(fun, js["abi"][i]["inputs"])
        if re.match("^prove", fun) or re.match("^check", fun):
            ret.append((fun, sig))

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


# A case to solve by the solvers
class Case:
    def __init__(self, contract: str, json_fname: str, sol_file: str,
                 ds: bool, fun: str, sig: str):
        self.contract = contract
        self.json_fname = json_fname
        self.sol_file = sol_file
        self.ds = ds
        self.fun = fun
        self.sig = sig
        self.expected = determine_expected(sol_file)

    def get_name(self) -> str:
        return "%s:%s:%s" % (self.sol_file, self.contract, self.fun)

    def __str__(self):
        out = ""
        out += "Contr: %-25s " % self.contract
        out += "Fun: %-20s " % self.fun
        out += "sig: %-20s " % self.sig
        out += "DS: %s " % self.ds
        out += "Safe: %s" % self.expected
        # out += "JSON filename: %s " % self.json_fname
        return out


# builds a mapping from solidity files to lists of contracts. we do this by
# parsing the foundry build output, since that's easier than parsing the actual
# solidity code to handle the case where a single solidity file contains
# multiple contracts
def gather_cases() -> list[Case]:
    build_forge()
    build_kontrol()
    # build a dictionary where the key is a directory in the foundry build
    # output, and the value is a list of contract names defined within
    output_jsons = {
        str(f): [j.stem for j in f.glob("*.json")]
        for f in Path("./out").iterdir()
        if f.is_dir() and f.name != "kompiled"
    }

    # replace the path to the output json with the path to the original solidity file
    cases: list[Case] = []
    for out_dir, contracts in output_jsons.items():
        for c in contracts:
            json_path = f"{out_dir}/{c}.json"
            if json_path.startswith("out/build-info"):
                continue
            with open(json_path) as oj:
                js = json.load(oj)
                sol_file: str = js["ast"]["absolutePath"]
                if sol_file.startswith("src/common/") or sol_file.startswith("lib/"):
                    continue
                ds_test = determine_dstest(sol_file)
                for f_and_s in get_relevant_funcs(js):
                    fname = os.path.basename(sol_file)
                    casename = f"{fname}:{c}:{f_and_s[0]}"
                    if opts.verbose:
                        print("Matching test pattern against: ", casename)
                    if re.match(opts.testpattern, casename):
                        cases.append(Case(c, json_path, sol_file, ds_test,
                                          f_and_s[0], f_and_s[1]))
    return cases


# Generates a unique temporary file. Can be run multi-threaded
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


# Result from a solver
class Result:
    def __init__(self, result: str, mem_used_MB: float|None, exit_status: int|None,
                 perc_CPU: int|None, t: float|None, tout: float|None, memoutMB: float|None,
                 case: Case, out:str):
        self.result = result
        self.exit_status = exit_status
        self.mem_used_MB = mem_used_MB
        self.perc_CPU = perc_CPU
        self.t = t
        self.tout = tout
        self.memoutMB = memoutMB
        self.case = case
        self.out = out


# executes the given tool script against the given test case and returns the
# result
def execute_case(tool: str, extra_opts: list[str], case: Case) -> Result:
    time_taken = None
    result = None
    res = None
    before = time.time_ns()
    fname_time = unique_file("output")
    toexec = ["time", "--verbose", "-o", "%s" % fname_time,
              tool, case.sol_file, case.contract, case.fun, case.sig,
              "%i" % case.ds, "%s" % opts.timeout, "%s" % (opts.memoutMB), "%d" % (opts.dump_smt)]
    toexec.extend(extra_opts)
    print("Running: %s" % (" ".join(toexec)))
    res = subprocess.run(toexec, capture_output=True, encoding="utf-8")
    after = time.time_ns()
    out_of_time = False
    mem_used_MB = None
    exit_status = None
    perc_CPU = None

    if opts.verbose:
        print("Res stdout is:", res.stdout)
        print("Res stderr is:", res.stderr)
    for line in res.stdout.split("\n"):
        line = line.strip()
        match = re.match("result: (.*)$", line)
        if match:
            result = match.group(1)
    time_taken = (after - before) / 1_000_000_000
    if out_of_time or result is None:
        result = "unknown"

    # parse `time --verbose` output
    with open(fname_time, 'r') as f:
        for line in f:
            line = line.strip()
            match = re.match(r"Maximum resident set size .kbytes.: (.*)", line)
            if match:
                mem_used_MB = int(match.group(1))/1000

            match = re.match(r"Percent of CPU this job got: (.*)%", line)
            if match:
                perc_CPU = int(match.group(1))

            match = re.match(r"Exit status:[ ]*(.*)[ ]*$", line)
            if match:
                exit_status = int(match.group(1))

    assert result == "safe" or result == "unsafe" or result == "unknown"
    os.unlink(fname_time)
    if opts.verbose:
        print("Result is: ", result)

    return Result(result=result, mem_used_MB=mem_used_MB,
                  perc_CPU=perc_CPU, exit_status=exit_status,
                  t=time_taken, tout=opts.timeout, memoutMB=opts.memoutMB, case=case, out=res.stderr)


def get_version(script: str) -> str:
    toexec = [script]
    print("Running: %s" % (" ".join(toexec)))
    res = subprocess.run(toexec, capture_output=True, encoding="utf-8")
    res.check_returncode()
    return res.stdout.rstrip()


# executes all tests contained in the argument cases mapping with all tools and
# builds the result dict
def run_all_tests(tools, cases: list[Case]) -> dict[str, list[Result]]:
    results: dict[str, list[Result]] = {}
    for tool, descr in tools.items():
        version = get_version(descr["version"])
        res = []
        for c in cases:
            res.append(execute_case(descr["call"], descr["extra_opts"], c))
        name = "%s-%s-tstamp-%s" % (tool, version, opts.timestamp)
        results[name] = res
    return results


# Encodes the 'Result' class into JSON
class ResultEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Result):
            solved = o.result == "safe" or o.result == "unsafe"
            if solved:
                correct = o.result == o.case.expected
            else:
                correct = None
            return {
                "name": o.case.get_name(),
                "solc_version": opts.solc_version,
                "ds": o.case.ds,
                "solved": solved,
                "correct": correct,
                "t": o.t,
                "tout": o.tout,
                "memMB": o.mem_used_MB,
                "exit_status": o.exit_status,
                "out": o.out}
        return json.JSONEncoder.default(self, o)


# Returns empty string if value is None. This is converted to NULL in SQLite
def empty_if_none(x: None|int|float) -> str:
    if x is None:
        return ""
    else:
        return "%s" % x


# Dump results in SQLite and CSV, so they can be analyzed via
# SQL/Libreoffice/commend line
def dump_results(solvers_results: dict[str, list[Result]], fname: str):
    with open("%s.json" % fname, "w") as f:
        f.write(json.dumps(solvers_results, indent=2, cls=ResultEncoder))
    with open("%s.csv" % fname, "w", newline='') as f:
        fieldnames = ["solver", "solc_version", "name", "fun", "sig", "result", "correct", "t", "timeout", "memoutMB", "memMB", "exit_status", "output"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for solver, results in solvers_results.items():
            for r in results:
                corr_as_sqlite = ""
                if r.result is not None:
                    corr_as_sqlite = (int)(r.result == r.case.expected)
                writer.writerow({
                    "solver": solver, "solc_version": opts.solc_version,
                    "name": r.case.get_name(), "fun": r.case.fun,
                    "sig": r.case.sig, "result": r.result,
                    "correct": corr_as_sqlite, "t": empty_if_none(r.t),
                    "timeout": r.tout,
                    "memoutMB": r.memoutMB,
                    "memMB": empty_if_none(r.mem_used_MB),
                    "exit_status": empty_if_none(r.exit_status), "output": r.out})


# --- main ---


# Set up options for main
def set_up_parser() -> optparse.OptionParser:
    usage = "usage: %prog [options]"
    desc = """Run all benchmarks for all tools
    """

    parser = optparse.OptionParser(usage=usage, description=desc)
    parser.add_option("--verbose", "-v", action="store_true", default=False,
                      dest="verbose", help="More verbose output. Default: %default")

    parser.add_option("-s", dest="seed", type=int, default=1,
                      help="Seed for random numbers. Default: %default")

    parser.add_option("--tests", dest="testpattern", type=str, default=".*",
                      help="Test pattern regexp in the format 'fname:contract:function'. Default: %default")

    avail = ", ".join([t for t,_ in available_tools.items()])
    parser.add_option("--tools", dest="tools", type=str, default="all",
                      help="Only run these tools (comma separated list). Available tools: %s" % avail)

    parser.add_option("--solcv", dest="solc_version", type=str, default="0.8.19",
                      help="solc version to use to compile contracts")

    parser.add_option("--dumpsmt", dest="dump_smt", default=False,
                      action="store_true", help="Ask the solver to dump SMT files, if the solver supports it")

    parser.add_option("-t", dest="timeout", type=int, default=25,
                      help="Max time to run. Default: %default")

    parser.add_option("-m", dest="memoutMB", type=int, default=16000,
                      help="Max memory per execution of the tool, in MB. Note that if your tool uses 16 threads, each 100MB, it will be counted as 1600MB. Default: %default")

    parser.add_option("--limit", dest="limit", type=int, default=100000,
                      help="Max number of cases to run. Default: %default")

    parser.add_option("--norebuild", dest="norebuild", default=False,
                      action="store_true", help="Don't rebuild with forge")

    parser.add_option("--yul", action="store_true", default=False,
                      dest="yul", help="Build through YUL pipeline in forge. You can then access the YUL via `cat myjson | jq '.ir'`.")

    return parser


def get_tools_used():
    ret = {}
    for tool in opts.tools.split(","):
        tool=tool.strip()
        if tool == "all":
            ret = available_tools
            break
        if tool == "":
            continue
        if tool not in available_tools:
            print("ERROR: tool you specified, '%s' is not known." % tool)
            print("Known tools: %s" % ", ".join([t for t, _ in available_tools.items()]))
            exit(-1)
        else:
            ret[tool] = available_tools[tool]

    return ret

def main() -> None:
    parser = set_up_parser()
    global opts
    (opts, args) = parser.parse_args()
    if len(args) > 0:
        print("Benchmarking does not accept arguments")
        exit(-1)
    random.seed(opts.seed)
    opts.timestamp = strftime("%Y-%m-%d-%H:%M", gmtime())
    tools_used = get_tools_used()
    print("Will run tool(s): %s" % ", ".join([t for t, _ in tools_used.items()]))
    if len(tools_used) == 0:
        print("ERROR: You selected no tools to run. Exiting.")
        exit(-1)

    cases = gather_cases()
    print(f"running {len(cases)} cases")
    cases.sort(key=lambda contr: contr.get_name())
    if len(cases) == 0:
        print(f"No cases gathered with test pattern '{opts.testpattern}'. Exiting.")
        exit(0)
    print(f"Cases gathered given test pattern '{opts.testpattern}':")
    for c in cases:
        print("-> %s" % c)
    random.shuffle(cases)
    solvers_results = run_all_tests(tools_used, cases[:opts.limit])
    results_fname = "results-tstamp-%s" % opts.timestamp
    dump_results(solvers_results, results_fname)
    os.system("cp %s.csv results-latest.csv" % results_fname)
    os.system("cp %s.json results-latest.json" % results_fname)
    print("Generated file %s.csv" % results_fname)
    print("Generated file %s.json" % results_fname)
    os.system("sqlite3 results.db < create_table.sql")
    os.system("sqlite3 results.db \". mode csv\" \". import -skip 1 %s.csv results\" \".exit\" " % results_fname)
    os.system("sqlite3 results.db < clean_table.sql")

if __name__ == "__main__":
    main()
