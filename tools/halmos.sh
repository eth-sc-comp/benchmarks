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
fi

if [[ "${ds_test}" == "0" ]]; then
    out=$(runlim --real-time-limit="${tout}" --kill-delay=2 --space-limit="${memout}" halmos --function "${fun_name}" --contract "${contract_name}" --symbolic-storage --symbolic-msg-sender ${extra_params} "$@" 2>&1)
elif [[ "${ds_test}" == "1" ]]; then
    out=$(runlim --real-time-limit="${tout}" --kill-delay=2 --space-limit="${memout}" halmos --function "${fun_name}" --contract "${contract_name}" ${extra_params} "$@" 2>&1)
else
    echo "Called incorrectly"
    exit 1
fi

# Check if we emitted smt2 files. If so, copy them over to a
# directory based on the contract file & name
set +x
if [[ "$dump_smt" == "1" ]] && [[ "$out" =~ "Generating SMT" ]]; then
    regexp="s/^Generating SMT queries in \\(.*\\)/\\1/"
    smtdir=$(echo "$out" | grep "Generating SMT" | sed -e "${regexp}")
    outdir="halmos-smt2/${contract_file}.${contract_name}/"
    mkdir -p "$dir"
    mv -f ${smtdir}/*.smt2 "${outdir}/"
fi

if [[ $out =~ "Counterexample: unknown" ]]; then
  echo "result: unknown"
  exit 0
fi

if [[ $out =~ "Counterexample (potentially invalid)" ]]; then
  echo "result: unknown"
  exit 0
fi

if [[ $out =~ "Encountered symbolic CALLDATALOAD offset" ]]; then
  echo "result: unknown"
  exit 0
fi

if [[ $out =~ "paths have not been fully explored due to the loop unrolling bound" ]]; then
  echo "result: unknown"
  exit 0
fi

if [[ $out =~ "Traceback" ]]; then
  exit 1
fi

if [[ $out =~ "Encountered symbolic memory offset" ]]; then
  echo "result: unknown"
  exit 0
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
