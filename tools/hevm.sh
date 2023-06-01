#!/usr/bin/env bash

set -euo pipefail

contract_file="$1" ; shift
contract_name="$1" ; shift

json_file="out/$(basename "${contract_file}")/${contract_name}.json"
bytecode=$(jq .deployedBytecode.object -r "${json_file}")

hevm symbolic --code "${bytecode}"
