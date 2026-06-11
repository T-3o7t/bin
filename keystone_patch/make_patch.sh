#!/bin/sh
set -e

cd ~/github/keystone
git diff -- . ':(exclude)buildroot' > keystone_options.patch

