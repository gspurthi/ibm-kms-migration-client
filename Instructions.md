__Dear IBM Key Protect User__: you are currently running active encryption keys on an older, legacy version of our Key Protect infrastructure. There have been many upgrades in key security, structure stability, compliance, and new capabilities. One of the newest features is giving you the ability to create your own encryption keys on-premisies then import the keys into Key Protect (this process is called BYOK - Bring Your Own Key). BYOK gives you more control over the security of the data and applications you are using in the IBM Cloud.

To enable these upgrades we have had to make several changes to our infrastrcuture. It is important that you take action as soon as possible to migrate your existing encryption keys from the old legacy structure into our newer version.

There are a few steps required for you to facilitate the migration. The Key Protect team will assist to walk you through the migration process. Once the migration is completed we will deprecate the legacy Key Protect service.

First and foremost please backup your existing encryption keys in order to maintain access to your data in case of inadvertent loss of keys during migration.

The enclosed package contains the scripts for migrating the standard secret keys from a legacy Key Protect service instance to a new Key Protect service instance

##### Pre-requisites:
 Create a new Key Protect instance for migrating the keys from legacy Key Protect instance
  - Go to https://console.bluemix.net and create a new account, or if you already have a new account, log in using your Bluemix account id and password
  - In the console page `Select Catalog -> Security and Identity -> Key Protect -> type in new service name or select the provided name - "[your service name]", "US South" (the region/location to deploy in), "default"(resource group) -> Create`


##### To set up migration client:

1. Extract the archive migration-client.zip into a directory "migration-client"
   Then
        $ cd migration-client

2. Set up following environment variables in file `envs`
           #Legacy account variables
           export CF_ORG=<Legacy Account Org Name>
           export CF_SPACE=<Legacy Account Space Name>
           export LEGACY_ACCOUNT_API_KEY=<Legacy Account api key>
           #New KP account variables
           export KP_ACCOUNT_API_KEY=<New Key Protect Account api key>
           export KP_SERVICE_INSTANCE_NAME=<New Key Protect Instance Name>
3. Get the environment variables information
   - Set the variables for the legacy Key Protect
     - Log in to the Bluemix console on https://console.bluemix.net
     - Select the account for the legacy Key Protect service from the user profile on the top right corner
     - Select Dashboard, find the values [org] and [space] for ORG_NAME and SPACE_NAME
     - Select Manage -> Security -> Platform API Keys -> Create
     -  Enter the key name and description -> Create -> save and copy the [legacy account key] to LEGACY_API_KEY
             export CF_ORG="[org]"
             export CF_SPACE="[space]"
             export LEGACY_ACCOUNT_API_KEY="[legacy account key]"
   - Set the variables for the new Key Protect instance
     -  Log in to the Bluemix console on https://console.bluemix.net
     - Select the new account for the new Key Protect service from the user profile on the top right corner
     - Select Dashboard, find the value [your service name] for KP_SERVICE_INSTANCE_NAME
     - Select Manage -> Security -> Platform API Keys -> Create
     - Enter the key name and description -> Create -> save and copy the [new account key] to KP_ACCOUNT_API_KEY
            export INSTANCE_NAME="[instance name]"
            export KP_API_KEY="[new account key]"

##### Migrate Keys

Run the client-wrapper.sh script to initiate standard key migration from your legacy instance

        migration-client> ./client-wrapper.sh

   - The standard secret keys migrated are recorded in file `migration.csv`
   - The keys in the legacy account remain there.
   - The migration run logs will be recorded in `migration-client.log`

  > NOTE: If migration fails in the middle of moving keys, the migration.csv file has the list of keys migrated. Please save the migration.csv file to resume the migration procress when re-run, otherwise all keys are moved again and there will be duplicate keys in the new instance.

- Login to https://console.bluemix.net and go to your key protect instance and list the keys to verify the legacy keys have been migrated.


##### Update your applications to new Key Protect service

   1. You need to update the applications to connect to the new Key Protect service.
    - Update to latest Key Protect endpoint `keyprotect.us-south.bluemix.net`

   2. The new Key Protect service stores keys in a based64 format, applications needed to be updated
    - To encode the key payload before creating a standard key with a shell command
            $ echo <payload> | base64
    - To decode the base64 key payload after retrieving it and before using it, with a shell command
            $ echo <base64-payload> | base64 -D

##### Testing migration and notifying to the team

- Perform a regression test on your applications

- Notify the Key Protect team that your migration has completed by sending an email to ""

Upon completion of the migration process you will now be able to take advantage of the of the new features of Key Protect while having the comfort that your encryption keys are now more secure and accessible than before.

##### Need help

If you need help with the migration or encounter a problem during a migration or in the regression test of your applications, please contact IBM Key Protect team via an email.
