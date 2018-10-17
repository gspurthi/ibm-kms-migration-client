#!/bin/bash

for id in `./kp list | sed '1d' | awk '{ print $1 }'`; do
    ./kp delete $id
done
