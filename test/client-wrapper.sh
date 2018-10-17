#!/bin/bash

# Legacy Key Protect instance
#LEGACY_ACCT=""
#ORG_NAME=""
#SPACE_NAME=""

# new Key Protect instance
#ACCT=""
#REGION="us-south"
#BLUEMIX_API_KEY=""
#INSTANCE_ID=""

export BLUEMIX_VERSION_CHECK=false

uaa_token_file=$(readlink -f ~/.uaatoken)
iam_token_file=$(readlink -f ~/.iamtoken)

function refresh_uaa_token {
    BX_APIKEY="${BLUEMIX_API_KEY}"
    export BLUEMIX_API_KEY=
    bx login -a https://api.ng.bluemix.net -c "$LEGACY_ACCT" -o "$ORG_NAME" -s "$SPACE_NAME"
    UAA_TOKEN=$(bx iam oauth-tokens | tail -n 1 | sed 's/UAA token:  //')
    ORG_ID=$(bx cf org "$ORG_NAME" --guid | tail -n 1)
    SPACE_ID=$(bx cf space "$SPACE_NAME" --guid | tail -n 1)

cat > $uaa_token_file <<-EOH
export UAA_TOKEN="${UAA_TOKEN}"
export ORG_ID="${ORG_ID}"
export SPACE_ID="${SPACE_ID}"
EOH

    BLUEMIX_API_KEY="${BX_APIKEY}"
}

function refresh_iam_token {
    BLUEMIX_API_KEY="${BLUEMIX_API_KEY}" bx login -a https://api.ng.bluemix.net
    bx iam oauth-tokens | awk '{print $3" "$4}' > $iam_token_file
}

if [[ ! -e $uaa_token_file ]]; then
    echo "UAA token file not found."
    refresh_uaa_token
fi
if [[ $(find $uaa_token_file -mmin +20) ]]; then
    echo "UAA token file old."
    refresh_uaa_token
fi

if [[ ! -e $iam_token_file ]]; then
    echo "IAM token file not found."
    refresh_iam_token
fi
if [[ $(find $iam_token_file -mmin +20) ]]; then
    echo "IAM token file old."
    refresh_iam_token
fi

IAM_TOKEN=$(cat $iam_token_file)
source $uaa_token_file

bin/migration-client --org-id="$ORG_ID" --space-id="$SPACE_ID" --uaa-token="$UAA_TOKEN" --instance-id="$INSTANCE_ID" --iam-token="$IAM_TOKEN"
