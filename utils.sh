#!/bin/bash
# IBM 2018 Copyright
# Key Protect Legacy Migration
#
# Utilities for Key Migration
# - login
# - export secret keys
# - import secret keys
# - list secret keys
#

#
# Log in to my account in Legacy KP
#
login_legacyKP(){
echo "# Log in to a Legacy KP account"

bx login -a https://api.ng.bluemix.net -u $USER -p $PASSWD -c $LEGACY_ACCT -o $ORG -s $SPACE
UAA_TOKEN=`bx iam oauth-tokens | tail -n 1 | sed 's/UAA token:  //'`
ORG_ID=`bx cf org kmprodt --guid | tail -n 1`
SPACE_ID=`bx cf space IAM_testing --guid | tail -n 1`
#echo "uaaToken:$UAA_TOKEN organization:$ORG_ID space:$SPACE_ID"
}

#
# Export secret keys from Legacy KP
#
export_secretkeys_legacyKP(){
list_secretkeys_legacyKP
echo "# Export the keys to legacy_keys.json"

GO=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['metadata']['collectionTotal']" 2> /dev/null`
if [ $GO -eq 0 ]
then
  COUNT=0
  echo "{\"count\":0}" > legacy_keys.json
  echo "   No secret keys to export"
else
  COUNT=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print len(obj['resources'])"`
  echo "{\"count\":\"$COUNT\", \"resources\":[" > legacy_keys.json
  echo "KEY COUNT $COUNT"
fi

for ((i=0; i < $COUNT ; i++))
do
  KEY_ID=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['id']"`
  PAYLOAD=""
  while [ -z "$PAYLOAD" ]  # retry until successful
  do
    curl -X GET https://ibm-key-protect.edge.bluemix.net/api/v2/keys/$KEY_ID --header "Authorization: $UAA_TOKEN" --header "Bluemix-Org: $ORG_ID" --header "Bluemix-Space: $SPACE_ID"  --header "Accept: application/json" &> tmpKEYS
    KEY_RESULT=`cat tmpKEYS | tail -n 1`
    ALGT=`echo $KEY_RESULT | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][0]['algorithmType']" 2> /dev/null`
    NAME=`echo $KEY_RESULT | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][0]['name']" 2> /dev/null`
    PAYLOAD=`echo $KEY_RESULT | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][0]['payload']" 2> /dev/null`
  done
  PAYLOAD_BASE64=`echo $PAYLOAD | base64`
  echo "{\"id\":\"$KEY_ID\",\"name\":\"$NAME\",\"algorithmType\":\"$ALGT\",\"payload\":\"$PAYLOAD\",\"payload_base64\":\"$PAYLOAD_BASE64\"}" >> legacy_keys.json
  if (( $i < $COUNT - 1 ));
  then
    echo "," >> legacy_keys.json
  else
    echo "]}" >> legacy_keys.json
  fi
  echo "  exported a key {\"id\":\"$KEY_ID\",\"name\":\"$NAME\",\"algorithmType\":\"$ALGT\",\"payload\":\"$PAYLOAD\",\"payload_base64\":\"$PAYLOAD_BASE64\"}"
  rm tmpKEYS
done
}

#
# Log in to my new KP account and optionally create an instance
#
login_newKP(){
echo "# Log into my new KP account and optionally create an instance"

bx login -a https://api.ng.bluemix.net -u $USER -p $PASSWD -c $ACCT
INST_ID=`bx resource service-instance "$INST" | grep GUID | sed 's/GUID://' | sed 's/ //g'`
if [[ -z $INST_ID ]]
then
  INST=`bx resource service-instance-create "$INST" kms tiered-pricing $REGION | tail -n 1 | cut -d ' ' -f 1`
  INST_ID=`bx resource service-instance "$INST" | grep GUID | sed 's/GUID://' | sed 's/ //g'`
  echo "# Created an KP instace $INST"
fi
IAM_TOKEN=`bx iam oauth-tokens | sed 's/IAM token:  //'`
echo "# KP instance name:$INST id:$INST_ID"
#echo "IAM token: $IAM_TOKEN"
}

#
# List all secret keys in a Legacy KP instance
#
list_secretkeys_legacyKP(){
echo "# List all secret keys in a Legacy KP instance"

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
      COUNT=`echo $KEYS | python -c 'import json,sys;obj=json.load(sys.stdin);print len(obj["resources"])'`
      echo "KEY COUNT $COUNT"
      for ((i=0; i < $COUNT ; i++))
      do
        NAME=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['name']" 2> /dev/null`
        ALGT=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['algorithmType']"`
        KEY_ID=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['id']"`
        echo "Key name:$NAME algorithmType:$AlGT id:$KEY_ID"
      done
    fi
  fi
done
}

#
# List all secret keys in a New KP instance
#
list_secretkeys_newKP(){
echo "# List all secret keys in a New KP instance"

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
        if [[ $EXTRACTABLE ]]  # list the secret key
        then
          NAME=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['name']" 2> /dev/null`
          ALGM=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['algorithmMode']"`
          ALGBS=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['algorithmBitSize']"`
          EXTRACTABLE=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['extractable']"`
          KEY_ID=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['id']"`
          echo "Secret key name:$NAME algorithmMode:$ALGM algorithmBitSize:$ALGBS id:$KEY_ID extractable:$EXTRACTABLE"
        fi
      done
    fi
  fi
done
}

#
# Get all the secret keys in the New KP instance
#
get_secretkeys_newKP(){
#echo "  get all the secret keys in the New KP instance"

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
      #echo "  KEY COUNT $COUNT"
    fi
  else
    COUNT=0
  fi
done
}

#
# Import keys from legacy_keys.json
#
import_secretkeys_newKP(){
echo "# Import secret keys from legacy_keys.json"

KEYSi=`cat legacy_keys.json`
COUNTi=`echo $KEYSi | python -c "import json,sys;obj=json.load(sys.stdin);print obj['count']"`
if [ $COUNTi -eq 0 ]
then
  echo "   No secret key is available to be imported"
fi
for ((ii=0; ii < $COUNTi ; ii++))
do
  NAMEi=`echo $KEYSi | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$ii]['name']" 2> /dev/null`

  # Check if the key of the name is already in the KP instance
  get_secretkeys_newKP
   # echo "Key list in the KP instance: $KEYS"
  EXIST=0
  for ((i=0; i < $COUNT && $EXIST == 0 ; i++))
  do  
    NAME=`echo $KEYS | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$i]['name']" 2> /dev/null`
    if [ "$NAMEi" == "$NAME" ]
    then 
      EXIST=1
    fi
  done

  # import the key only if it does not exist in the KP instance
  if (( $EXIST == 0 ))
  then
    ALGTi=`echo $KEYSi | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$ii]['algorithmType']" 2> /dev/null`
    PAYLOADi=`echo $KEYSi | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$ii]['payload']" 2> /dev/null`
    PAYLOADi_BASE64=`echo $KEYSi | python -c "import json,sys;obj=json.load(sys.stdin);print obj['resources'][$ii]['payload_base64']" 2> /dev/null`

    # create the key
    curl -X POST https://keyprotect.us-south.bluemix.net/api/v2/keys --header "Prefer: return=minimal" --header "Authorization: $IAM_TOKEN" --header "Bluemix-Instance: $INST_ID" --header "Accept: application/json" -d "{\"metadata\": {\"collectionType\": \"application/vnd.ibm.kms.key+json\", \"collectionTotal\": 1}, \"resources\": [{\"name\": \"$NAMEi\", \"type\": \"application/vnd.ibm.kms.key+json\", \"extractable\":true, \"algorithmType\": \"$ALGTi\", \"payload\": \"$PAYLOADi_BASE64\" }]}" &> tmp
    KEY_ID=`tail -n 1 tmp | sed "s/.*{\"id\":\"//" | sed "s/\",\"type.*//"`

    # retrive the key to make sure we have it in the instance now
    curl -X GET https://keyprotect.us-south.bluemix.net/api/v2/keys/$KEY_ID --header "Authorization: $IAM_TOKEN" --header "Bluemix-Instance: $INST_ID" --header "Accept: application/vnd.ibm.kms.key+json"
    echo "  imported the key with name:$NAMEi id:$KEY_ID" 
  else
    echo "  The key with name:$NAMEi and already exists and is not imported." 
  fi

done
}

