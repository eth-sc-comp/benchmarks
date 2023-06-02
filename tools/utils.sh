#!/usr/bin/env bash

# takes a path to a solidity file and a contract name and returns the runtime bytecode
get_runtime_bytecode() {
    solidity_file=$1
    contract_name=$2
    filename=$(basename "${solidity_file}")
    json_file="out/${filename}/${contract_name}.json"
    jq .deployedBytecode.object -r "${json_file}"
}
