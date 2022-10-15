#!/bin/bash
set -e

function banner() {
  # these leading dashes are necessary for printing dashes 
  # so that the dashes aren't interpreted as a cli --arg
  printf '\n\n'
  printf -- '-%.0s' {1..40}
  printf '\n %s \n' $1
  printf -- '-%.0s' {1..40}
  printf '\n'
}


FILE=test/main.roc
EXE=${FILE%.roc}
banner $FILE
roc build $FILE
foo=bar $EXE arg1 arg2


FILE=test/file-read-errors.roc
EXE=${FILE%.roc}
banner $FILE
roc build $FILE
EXPECTEDS=("NotFound" "Interrupted" "InvalidFilename" "PermissionDenied" "TooManySymlinks" "TooManyHardlinks" "TimedOut" "StaleNetworkFileHandle" "OutOfMemory" "Unsupported" "Unrecognized")
for EXPECTED in ${EXPECTEDS[@]} ; do
  ACTUAL=$($EXE $EXPECTED 2>/dev/null)
  # make sure output starts with EXPECTED
  if [[ $ACTUAL != $EXPECTED* ]]; then
    echo "Error: $ACTUAL != $EXPECTED in $FILE"
    exit 1
  fi
done
echo "Success in $FILE"
