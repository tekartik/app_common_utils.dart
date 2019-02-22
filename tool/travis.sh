#!/bin/bash

# Fast fail the script on failures.
set -xe

pushd app
pub get
tool/travis.sh
popd
