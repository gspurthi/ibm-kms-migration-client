#!/bin/bash

#INSTANCE_ID=""
#BLUEMIX_API_KEY=""
export BLUEMIX_VERSION_CHECK=false

iam_token_file=$(readlink -f ~/.iamtoken)

function refresh_iam_token {
    BLUEMIX_API_KEY="${BLUEMIX_API_KEY}" bx login -a https://api.ng.bluemix.net
    bx iam oauth-tokens | awk '{print $3" "$4}' > $iam_token_file
}


if [[ ! -e $iam_token_file ]]; then
    echo "IAM token file not found."
    refresh_iam_token
fi
if [[ $(find $iam_token_file -mmin +20) ]]; then
    echo "IAM token file old."
    refresh_iam_token
fi

IAM_TOKEN=$(cat $iam_token_file)

bin/kp --instance-id=$INSTANCE_ID --iam-token="$IAM_TOKEN" $@
