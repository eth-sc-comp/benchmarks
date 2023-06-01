#!/usr/bin/env/python3

import subprocess
import os
import glob
from pathlib import Path
import time
import copy
import json

SOLC_VERSION = "0.8.19"
TIMEOUT = 5 * 60 # 5 minutes

# get a list of all test files and test contracts...
subprocess.run(["forge", "build", "--use", SOLC_VERSION], capture_output=True)

# build a dictionary where the key is the solidity file, and the value is a list of contract names defined within
# produced by iterating over the foundry build output
cases = {
    str(f): [j.stem for j in f.glob("*.json")] for f in Path("./out").iterdir() if f.is_dir()
}
# strip utils.sol (contains no tests)
cases.pop("out/utils.sol", None)


# tools names -> harness scripts
tools = {"hevm": "tools/hevm.sh"}

# execute each tool on each testcase and write the execution times to a dictionary (tool -> file -> contract -> time)
results = copy.deepcopy(tools)
for t, script in tools.items():
    print(f"{t}:")
    results[t] = copy.deepcopy(cases)
    for file, contracts in results[t].items():
        results[t][file] = {}
        for c in contracts:
            print(f"  {file}:{c}:")
            # determine whether or not the contract is expected to be safe or unsafe
            expected = ""
            with open(f"{file}/{c}.json") as oj:
                methods = json.load(oj)["methodIdentifiers"]
                if "UNSAFE()" in methods:
                    expected = "unsafe"
                if "SAFE()" in methods:
                    assert(expected != "unsafe")
                    expected = "safe"
                assert(expected == "safe" or expected == "unsafe")
            before = time.time_ns()
            try:
                res = subprocess.run([script, file, c], capture_output=True, encoding="utf-8", timeout=TIMEOUT)
            except timeout.TimeoutExpired:
                results[t][file][c] = { "result": "unknown", "expected": expected, "time_taken": TIMEOUT*1000}
            else:
                after = time.time_ns()
                results[t][file][c] = { "result": res.stdout.rstrip(), "expected": expected, "time_taken": (after - before) // 1000000 }
            print(f"    {results[t][file][c]['result']} ({results[t][file][c]['time_taken']} ms)")

# write the results to disk as json
with open('results.json', 'w') as res:
    res.write(json.dumps(results, indent=2))
