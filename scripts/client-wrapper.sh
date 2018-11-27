#!/bin/bash
source envs

function get_legacy_acc_info {
    echo "==  logging to legacy account"
    echo
    bx login -a https://api.ng.bluemix.net --apikey $LEGACY_ACCOUNT_API_KEY
    echo "==  targetting to org and space"
    echo
    bx target --cf-api https://api.ng.bluemix.net -o "$CF_ORG" -s "$CF_SPACE"
    ORG_ID=$(bx cf org "$CF_ORG" --guid | tail -n 1)
    SPACE_ID=$(bx cf space "$CF_SPACE" --guid | tail -n 1)
    echo "==  obtained org_id, space_id"
    echo
}

function get_new_acc_info {
    echo "==  logging to new account"
    echo
    bx login -a https://api.ng.bluemix.net --apikey $KP_ACCOUNT_API_KEY
    KP_SERVICE_INSTANCE_ID=$(bx resource service-instance "$KP_SERVICE_INSTANCE_NAME" | grep GUID: | sed 's/GUID://' | sed 's/ //g')
    IAM_TOKEN=$(bx iam oauth-tokens | awk '{print $3" "$4}')
    echo "==  obtained iam_token, kp_service_instance_id"
    echo
}

echo
echo "== getting legacy account info"
get_legacy_acc_info

echo
echo "== getting new account info"
get_new_acc_info

echo
echo "== running key migration"
./bin/migration-client --org-id="$ORG_ID" --space-id="$SPACE_ID" --instance-id="$KP_SERVICE_INSTANCE_ID" --iam-token="$IAM_TOKEN" &> migration-client.log
echo

if [[ -f migration-client.log && -s migration-client.log ]]
then
	echo "== key migration script completed, please review migration-client.log file for detail"
fi
