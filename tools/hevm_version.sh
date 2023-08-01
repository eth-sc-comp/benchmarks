#!/usr/bin/env bash

ver=$(hevm version 2>/dev/null)
verclean=$(echo "${ver}" | awk '{print $1}')
echo "${verclean}"
