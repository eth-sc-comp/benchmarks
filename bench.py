#!/usr/bin/env/python3

import subprocess
from pathlib import Path
import time
import copy
import json
from typing import Dict, Tuple, Any, Literal

SOLC_VERSION = "0.8.19"
TIMEOUT = 5 * 60  # 5 minutes
tools = {"hevm": "tools/hevm.sh"}


def build_contracts() -> None:
    subprocess.run(["forge", "build", "--use", SOLC_VERSION], capture_output=True)


# builds a mapping from solidity files to lists of contracts. we do this by
# parsing the foundry build output, since that's easier than parsing the actual
# solidity code to handle the case where a single solidity file contains
# multiple contracts
def gather_cases() -> Dict[str, list[str]]:
    # build a dictionary where the key is a directory in the foundry build
    # output, and the value is a list of contract names defined within
    output_jsons = {
        str(f): [j.stem for j in f.glob("*.json")]
        for f in Path("./out").iterdir()
        if f.is_dir()
    }

    # replace the path to the output json with the path to the original solidity file
    cases: Dict[str, list[str]] = {}
    for out_dir, contracts in output_jsons.items():
        for c in contracts:
            with open(f"{out_dir}/{c}.json") as oj:
                sol_file: str = json.load(oj)["ast"]["absolutePath"]
                cases.setdefault(sol_file, [])
                cases[sol_file].append(c)
    return cases


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


# executes the given tool script against the given test case and returns the
# time taken and the reported result
def execute_contract(tool: str, sol_file: str, contract: str) -> Tuple[int, str]:
    time_taken = None
    result = None
    before: int = time.time_ns()
    try:
        res = subprocess.run(
            [tool, sol_file, contract],
            capture_output=True,
            encoding="utf-8",
            timeout=TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        result = "unknown"
        time_taken = TIMEOUT * 1000
    else:
        after: int = time.time_ns()
        result = res.stdout.rstrip()
        time_taken = (after - before) // 1_000_000

    assert result == "safe" or result == "unsafe" or result == "unknown"
    return (time_taken, result)


# executes all tests contained in the argument cases mapping with all tools and
# builds the result dict
def run_all_tests(
    cases: Dict[str, list[str]]
) -> Dict[str, Dict[str, Dict[str, str | int]]]:
    # execute each tool on each testcase and write the execution times to a
    # dictionary (tool -> file -> contract -> (expected, result, time_taken))
    results: Dict[str, Any] = copy.deepcopy(tools)
    for t, script in tools.items():
        print(f"{t}:")
        results[t] = copy.deepcopy(cases)
        for file, contracts in results[t].items():
            results[t][file] = {}
            for c in contracts:
                print(f"  {file}:{c}:")
                expected = determine_expected(file)
                (time, result) = execute_contract(script, file, c)
                results[t][file][c] = {
                    "result": result,
                    "expected": expected,
                    "time_taken": time,
                }

                print(f"    {result} ({time} ms)")
    return results


# --- main ---


def main() -> None:
    build_contracts()
    cases = gather_cases()
    results = run_all_tests(cases)
    with open("results.json", "w") as res:
        res.write(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
