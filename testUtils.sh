#!/bin/bash
# IBM 2018 Copyright
# Key Protect Legacy Migration
#
# Utilities for migration testing (not for customers)
# - delete all secret keys
# - create secret keys
#

#
# Delete one secret key from a Legacy KP instance
# 
delete_secretkey_legacyKP(){
echo "# delete a secret key from a Legacy KP instance"

STATUS1="error"
while [[ ! -z "$STATUS1" ]]  # retry until successful
do
  curl -X DELETE https://ibm-key-protect.edge.bluemix.net/api/v2/keys/$KEY_ID --header "Authorization: $UAA_TOKEN" --header "Bluemix-Org: $ORG_ID" --header "Bluemix-Space: $SPACE_ID"  --header "Accept: application/json" &> tmpResult
  STAT=`cat tmpResult | tail -n 1`
  STATUS1=`echo $STAT | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][0]['errorMsg']" 2> /dev/null`
  if [[ ! -z $STATUS1 ]]
  then
    echo "  status:$STATUS1 (If Not Found, may need to manually delete the stalled key from the DB"
  fi
done
}

#
# Delete all secret keys from a Legacy KP instance
#
delete_secretkeys_legacyKP(){
echo "# Delete all secret keys from a Legacy KP instance"

GO=1
STATUS="error"
while [[ $GO -ne 0 && ! -z "$STATUS" ]]  # retry until successful
do
  curl -X GET https://ibm-key-protect.edge.bluemix.net/api/v2/keys --header "Authorization: $UAA_TOKEN" --header "Bluemix-Org: $ORG_ID" --header "Bluemix-Space: $SPACE_ID" --header "Accept: application/json" &> tmpKEYS
  KEYS=`cat tmpKEYS | tail -n 1`
  GO=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['metadata']['collectionTotal']" 2> /dev/null`
  if [[ $GO -ne 0 ]]
  then
    STATUS=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][0]['errorMsg']" 2> /dev/null`
    if [[ -z "$STATUS" ]]
    then
      COUNT=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print len(obj['resources'])"`
      echo "KEY COUNT $COUNT"
      for ((i=0; i < $COUNT ; i++))
      do
        NAME=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['name']" 2> /dev/null`
        KEY_ID=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['id']"`
        ALGT=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['algorithmType']"`
        delete_secretkey_legacyKP
        echo "  deleted a key name:$NAME id:$KEY_ID algorithmType:$ALGT"
      done
    fi
  fi
done
}

#
# Delete one secret key from a new KP instance
#
delete_secretkey_newKP(){
echo "# Delete a secret key from a new KP instance"

STATUS1="error"
while [[ ! -z "$STATUS1" ]]  # retry until successful
do
  curl -X DELETE https://keyprotect.us-south.bluemix.net/api/v2/keys/$KEY_ID --header "Prefer: return=minimal" --header "Authorization: $IAM_TOKEN" --header "Bluemix-Instance: $INST_ID" --header "Accept: application/json" &> tmpResult
  STAT=`cat tmpResult | tail -n 1`
  STATUS1=`echo $STAT | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][0]['errorMsg']" 2> /dev/null`
  if [[ ! -z $STATUS1 ]]
  then
    echo "   error: $STATUS1"
  fi
done
}

#
# Delete all secret keys from a New KP instance
#
delete_secretkeys_newKP(){
echo "# Delete all secret keys from a New KP instance"

GO=1
STATUS="error"
while [[ $GO -ne 0 && ! -z "$STATUS" ]]  # retry until successful
do
  curl -X GET https://keyprotect.us-south.bluemix.net/api/v2/keys --header "Authorization: $IAM_TOKEN" --header "Bluemix-Instance: $INST_ID" --header "Accept: application/json" &> tmpKEYS
  KEYS=`cat tmpKEYS | tail -n 1`
  GO=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['metadata']['collectionTotal']" 2> /dev/null`
  if [[ $GO -ne 0 ]]
  then
    STATUS=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][0]['errorMsg']" 2> /dev/null`
    if [[ -z "$STATUS" ]] 
    then
      COUNT=`echo $KEYS | python -c 'import json,sys;obj=json.load(sys.stdin);print len(obj["resources"])'`
      echo "KEY COUNT $COUNT" 
      for ((i=0; i < $COUNT ; i++))
      do
        EXTRACTABLE=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['extractable']"`
        if [[ $EXTRACTABLE ]]  # delete the key
        then
          NAME=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['name']" 2> /dev/null`
          ALGM=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['algorithmMode']"`
          ALGTBS=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['algorithmBitSize']"`
          KEY_ID=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['id']"`
          delete_secretkey_newKP
          echo "  deleted a secret key name:$NAME algorithmMode:$ALGM algorithmBitSize: $ALGBS keyID:$KEY_ID"
        fi
      done
    fi
  fi
done
}

#
# Create test data (secret keys) in a Legacy KP instance
#
create_testkeys_legacyKP(){
echo "# Create secret keys in a legacy KP instance"

curl -X POST https://ibm-key-protect.edge.bluemix.net/api/v2/keys  --header "Authorization: $UAA_TOKEN" --header "Bluemix-Org: $ORG_ID" --header "Bluemix-Space: $SPACE_ID"  --header "Accept: application/json" -d '{"metadata": {"collectionType": "application/vnd.ibm.kms.secret+json","collectionTotal": 1},"resources": [{"type": "application/vnd.ibm.kms.secret+json","name": "test_secret0", "algorithmType": "aes","payload": "demokeyfullofsecrets0"}]}'

curl -X POST https://ibm-key-protect.edge.bluemix.net/api/v2/keys  --header "Authorization: $UAA_TOKEN" --header "Bluemix-Org: $ORG_ID" --header "Bluemix-Space: $SPACE_ID"  --header "Accept: application/json" -d '{"metadata": {"collectionType": "application/vnd.ibm.kms.secret+json","collectionTotal": 1},"resources": [{"type": "application/vnd.ibm.kms.secret+json","name": "test_secret1", "algorithmType": "aes","payload": "demokeyfullofsecrets1"}]}'

curl -X POST https://ibm-key-protect.edge.bluemix.net/api/v2/keys  --header "Authorization: $UAA_TOKEN" --header "Bluemix-Org: $ORG_ID" --header "Bluemix-Space: $SPACE_ID"  --header "Accept: application/json" -d '{"metadata": {"collectionType": "application/vnd.ibm.kms.secret+json","collectionTotal": 1},"resources": [{"type": "application/vnd.ibm.kms.secret+json","name": "test_secret2", "algorithmType": "aes","payload": "demokeyfullofsecrets2"}]}'

curl -X POST https://ibm-key-protect.edge.bluemix.net/api/v2/keys  --header "Authorization: $UAA_TOKEN" --header "Bluemix-Org: $ORG_ID" --header "Bluemix-Space: $SPACE_ID"  --header "Accept: application/json" -d '{"metadata": {"collectionType": "application/vnd.ibm.kms.secret+json","collectionTotal": 1},"resources": [{"type": "application/vnd.ibm.kms.secret+json","name": "test_secret3", "algorithmType": "aes","payload": "demokeyfullofsecrets3"}]}'

curl -X POST https://ibm-key-protect.edge.bluemix.net/api/v2/keys  --header "Authorization: $UAA_TOKEN" --header "Bluemix-Org: $ORG_ID" --header "Bluemix-Space: $SPACE_ID"  --header "Accept: application/json" -d '{"metadata": {"collectionType": "application/vnd.ibm.kms.secret+json","collectionTotal": 1},"resources": [{"type": "application/vnd.ibm.kms.secret+json","name": "test_secret4", "algorithmType": "aes","payload": "demokeyfullofsecrets4"}]}'

}

