#!/usr/bin/env bash

contract_file="$1" ; shift
contract_name="$1" ; shift

json_file="out/$(basename "${contract_file}")/${contract_name}.json"
bytecode=$(jq .deployedBytecode.object -r "${json_file}")

out=$(hevm symbolic --code "${bytecode}")

if [[ $out =~ "QED: No reachable property violations discovered" ]]; then
  echo "safe"
  exit 0
fi

if [[ $out =~ "Discovered the following counterexamples" ]]; then
  echo "unsafe"
  exit 0
fi

if [[ $out =~ "Could not determine reachability of the following end states" ]]; then
  echo "unknown"
  exit 0
fi

exit 1
