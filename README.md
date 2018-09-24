# migration-client

This package contains the scripts for migrating the standard secret keys from a legacy Key Protect service instance to a new Key Protect service instance

# usage

The following is the procedure for the migration.

1. Create a new Key Protect instance and get information ready
 
   - log in to https://console.bluemix.net using [your Bluemix account id] and [your password]
   - Create a new Key Protect instance
     - Catelog -> Security and Identity -> Key Protect -> type or select - "[your service instance name]", "US South" (the region name), "default" -> Create
   - On a command window, run> bx login -a https://api.ng.bluemix.net -u [your Bluemix account id] -p [your password]
     - record the [Legacy account id] used for the Legacy Key Protect instance
     - record the [new account id] used for the new Key Protect instance
   - run> bx target --cf
     - record the [Org name] and the [Space name] used for the Legacy Key Protect instance

2. Configure the migration by updating the variables in config.sh 

     USER="[your Bluemix account id]"
     PASSWD="[your password]"

     LEGACY_ACCT="[legacy account id]"
     ORG="[Org name]"
     SPACE="[Space name]"

     ACCT="[new account id]"
     INST="[your service instance name]"
     REGION="us-south"

3. run> ./migr.sh

   to export the standard secret keys from your legacy Key Protect instance to legacy_keys.json
   and to import the keys from legacy_keys.json in base64 format to the new Key Protect instance
   and list the resulting set of standard secret keys in the new Key Protect instance

5. Update your applications that connect to and use the legacy Key Protect service instance 

   - change the end point - follow "this instruction II"
   - update your applications to convert the payload, by calling base64 (payload), and pass a base64 payload to a create key api 
   - update your applications to convert the base64 payload to original payload, by calling xxxx (base64 payload)  as the base64 payload is returned from a get key api

6. Perform a regression test of you applications

7. Notify the Key Protect team that your migration has completed by sending an email to ""

If you need help with the migration or encounter a problem during a migration or in the regression test of your applications, please contact the Key Protect team via an email tto ""

