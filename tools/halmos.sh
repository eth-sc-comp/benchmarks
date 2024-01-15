#!/usr/bin/env bash

set -x

contract_file="$1" ; shift
contract_name="$1" ; shift
fun_name="$1"; shift
sig="$1"; shift
ds_test="$1"; shift
tout="$1"; shift
memout="$1"; shift
dump_smt="$1"; shift

extra_params=""
if [[ "$dump_smt" == "1" ]]; then
    extra_params="${extra_params} --dump-smt-queries"
    rm -f ./*.smt2
fi


out=$(runlim --real-time-limit="${tout}" --kill-delay=2 --space-limit="${memout}" halmos --function "${fun_name}" --contract "${contract_name}" ${extra_params} "$@" 2>&1)


# Check if we emitted smt2 files. If so, copy them over to a
# directory based on the contract file & name
set +x
if [[ "$dump_smt" == "1" ]] && [[ "$out" =~ "Generating SMT" ]]; then
    a="s/^Generating SMT queries in \\(.*\\)/\\1/"
    outdir=$(echo "$out" | grep "Generating SMT" | sed -e "${a}")
    dir="halmos-smt2/${contract_file}.${contract_name}/"
    mkdir -p "$dir"
    mv -f ${outdir}/*.smt2 "$dir/"
    set -x
fi

if [[ $out =~ "WARNING:Halmos:Counterexample: unknown" ]]; then
  exit 1
fi

if [[ $out =~ "Traceback" ]]; then
  exit 1
fi

if [[ $out =~ "[FAIL]" ]]; then
  echo "result: unsafe"
  exit 0
fi

if [[ $out =~ "[PASS]" ]]; then
  echo "result: safe"
  exit 0
fi

exit 1
