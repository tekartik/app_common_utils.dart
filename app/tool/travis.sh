#!/bin/bash

# Fast fail the script on failures.
set -xe

dartanalyzer --fatal-warnings --fatal-infos lib test

# pub run build_runner test -- -p vm
pub run test -p vm,chrome