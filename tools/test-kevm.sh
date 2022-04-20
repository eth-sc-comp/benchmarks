#!/usr/bin/env bash

set -euo pipefail

contract_file="$1" ; shift
contract_name="$1" ; shift

contract_dir="$(dirname ${contract_file})"
contract_k="${contract_dir}/bin-runtime.k"

kevm solc-to-k "${contract_file}" "${contract_name}"
cat "${contract_k}"
