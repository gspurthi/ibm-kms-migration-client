#!/bin/bash

KP_BIN="bash scripts/kp-wrapper.sh"

for id in `$KP_BIN list | sed '1d' | awk '{ print $1 }'`; do
    $KP_BIN delete $id
done
