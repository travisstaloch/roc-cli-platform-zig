#!/bin/bash
set -e
roc build test/main.roc 
foo=bar test/main arg1 arg2
