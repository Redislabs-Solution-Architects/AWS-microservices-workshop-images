#!/bin/bash
[ $# -eq 3 ] || {
    echo "Expected 3 args: jq_filter cloud_formation_json s3_bucket. Got $#. Exiting"
    exit 1
    }
jq -f $1 $2 >cfn.json &&
    aws s3 cp cfn.json $3
