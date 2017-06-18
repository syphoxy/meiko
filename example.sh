#!/bin/bash

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

cd "$PROGDIR"

ruby -Ilib example.rb "$@"
