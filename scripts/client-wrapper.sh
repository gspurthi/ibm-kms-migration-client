#!/bin/bash

. envs

# stop bx/ibmcloud tool update alert
export BLUEMIX_VERSION_CHECK=false

die() {
    [ -n "$1" ] && echo "$*" >&2
    exit 1
}

# log in to bluemix interactively
# if you have multiple accounts, be sure to pick the account where your legacy KeyProtect instance is located
bx login --sso

# target the cloudfoundry org/space
bx target --cf-api https://api.ng.bluemix.net -o "$CF_ORG" -s "$CF_SPACE"

# gather GUID information for org/space
ORG_ID=$(bx cf org "$CF_ORG" --guid | tail -n 1)
SPACE_ID=$(bx cf space "$CF_SPACE" --guid | tail -n 1)

# optional: log into account with new legacy keyprotect instance
# if your new instance is in the same account (likely), we can skip this
[ -n "$KP_ACCOUNT_ID" ] && bx target -c $KP_ACCOUNT_ID

# gather new KeyProtect instance ID
KP_SERVICE_INSTANCE_ID=$(bx resource service-instance "$KP_SERVICE_INSTANCE_NAME" | grep GUID: | sed 's/GUID://' | sed 's/ //g')
[ -n "$KP_SERVICE_INSTANCE_ID" ] || die "error: couldn't retrieve the instance ID for instance '$KP_SERVICE_INSTANCE_NAME'"

# get an IAM token so we can authenticate to KeyProtect
IAM_TOKEN=$(bx iam oauth-tokens | awk '/IAM token:/ {print $3" "$4}')

# kick off the migration with the information we gathered above
echo "running: ./migration-client --org-id=$ORG_ID --space-id=$SPACE_ID --instance-id=$KP_SERVICE_INSTANCE_ID --iam-token=\"$IAM_TOKEN\""
./migration-client --org-id="$ORG_ID" --space-id="$SPACE_ID" --instance-id="$KP_SERVICE_INSTANCE_ID" --iam-token="$IAM_TOKEN"
if [ $? -eq 0 ]; then
    echo "migration-client completed successfully. check 'migration.csv' for keys that were migrated"
else
    die "migration-client hit an error"
fi
