#!/usr/bin/env/python3

import subprocess
import os
import glob
from pathlib import Path
import time
import copy
import json

SOLC_VERSION = "0.8.19"

# get a list of all test files and test contracts...
subprocess.run(["forge", "build", "--use", SOLC_VERSION])

# build a dictionary where the key is the solidity file, and the value is a list of contract names defined within
# produced by iterating over the foundry build output
cases = {
    str(f): [j.stem for j in f.glob("*.json")] for f in Path("./out").iterdir() if f.is_dir()
}

# tools names -> harness scripts
tools = {"hevm": "tools/hevm.sh"}

# execute each tool on each testcase and write the execution times to a dictionary (tool -> file -> contract -> time)
results = copy.deepcopy(tools)
for t, script in tools.items():
    results[t] = copy.deepcopy(cases)
    for file, contracts in results[t].items():
        results[t][file] = {}
        for c in contracts:
            before = time.time_ns()
            res = subprocess.run([script, file, c], capture_output=True, encoding="utf-8")
            after = time.time_ns()
            results[t][file][c] = { "result": res.stdout.rstrip(), "time_taken": (after - before) // 1000000 }

# write the results to disk as json
with open('results.json', 'w') as res:
    res.write(json.dumps(results, indent=2))
