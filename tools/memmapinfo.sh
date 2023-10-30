#!/bin/bash

# script to filter rgbds generated .map file...

_tools_dir="$(dirname ${0})"
_proj_dir="$(dirname ${_tools_dir})"
_map_file="${_proj_dir}/target/bin/gigantgolf.map"

if [[ $# -gt 0 ]]; then
  _map_file="$1"
fi

if [ ! -f "$_map_file" ]; then
  echo "file not found (${_map_file})"
  exit 1
fi


filter_labels() {
  grep -E -v '\$[a-fA-F0-9]{4} ='
}

get_area() {
  sed -n -e "/^$1/,/^$/ p"
}

# get ROMX section list
cat "$_map_file" | filter_labels | get_area 'ROMX bank #1:'

