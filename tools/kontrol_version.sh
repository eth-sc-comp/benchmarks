#!/usr/bin/env bash

ver=$(kontrol version 2>/dev/null)
verclean=$(echo "${ver}" | awk '{print $3}')
echo "${verclean}"
