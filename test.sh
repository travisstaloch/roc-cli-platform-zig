#!/bin/bash
set -e
roc build platform-test/main.roc 
foo=bar platform-test/platform-main arg1 arg2
