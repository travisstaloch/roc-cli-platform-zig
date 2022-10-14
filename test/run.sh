#!/bin/bash
set -e

printf "\nmain\n"
roc build test/main.roc 2>&1> /dev/null
foo=bar test/main arg1 arg2

printf "\nfile-read-errors\n"
roc build test/file-read-errors.roc 2>&1> /dev/null
EXPECTEDS=("NotFound" "Interrupted" "InvalidFilename" "PermissionDenied" "TooManySymlinks" "TooManyHardlinks" "TimedOut" "StaleNetworkFileHandle" "OutOfMemory" "Unsupported" "Unrecognized")
for EXPECTED in ${EXPECTEDS[@]} ; do
  ACTUAL=$(test/file-read-errors $EXPECTED 2> /dev/null) 
  # make sure output starts with expected
  if [[ $ACTUAL != $EXPECTED* ]]; then
    echo "Error: $ACTUAL != $EXPECTED"
    exit 1
  fi
done
echo "Success"
