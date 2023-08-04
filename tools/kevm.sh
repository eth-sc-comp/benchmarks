#!/usr/bin/env bash

set -euo pipefail

contract_file="$1" ; shift
contract_name="$1" ; shift
fun_name="$1"; shift
ds_test="$1"; shift
tout="$1"; shift

contract_dir="$(dirname "${contract_file}")"
contract_k="${contract_dir}/.k-artifacts/bin-runtime.k"
mkdir -p "$(dirname "${contract_k}")"

doalarm -t alarm "${tout}" kevm solc-to-k "${contract_file}" "${contract_name}" > "${contract_k}"
cat "${contract_k}"
