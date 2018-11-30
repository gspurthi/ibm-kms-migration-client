
# migration-client

[![Build Status](https://travis-ci.org/locke105/ibm-kms-migration-client.svg?branch=master)](https://travis-ci.org/locke105/ibm-kms-migration-client)

IBM® Key Protect service instances provisioned before 15 December 2017 are running on a legacy infrastructure that is based on Cloud Foundry. To enable fine-grained access control with Cloud IAM and other service improvements, we recommend that teams migrate their Key Protect keys into a newly provisioned instance of Key Protect.

Use this go client to migrate your existing encryption keys into a new Key Protect service instance, so that you may take advantage of the latest IBM Cloud platform functionalities, enhanced security, and expanded availability of our service.

>**Note:** This utility requires the [IBM Cloud CLI](https://console.bluemix.net/docs/cli/reference/ibmcloud/download_cli.html#install_use) as a prerequisite.

## How it works

This utility looks for active Key Protect keys that are stored within the specified Cloud Foundry space and organization in your IBM Cloud account. When you run the client, the utility copies each encryption key into a new Key Protect service instance, where you can continue to manage the lifecycle of the keys and leverage new service capabilities.

Keep in mind the following updates:

- **The identifying information for each key, such as the key metadata and the key ID, will be different after the key is migrated into the new Key Protect service instance.** The client migrates only the key material (the `payload` value) for each encryption key. To run the migrated keys on your existing applications, you must update any references to the old key IDs so that they reflect the new key ID values.  
- **You must update your applications to handle the newly base64 encoded key payloads.** New Key Protect service instances require the `payload` value for each key will to be encoded to base64. This client handles base64 encoding on your behalf as part of the migration process, but you will need to handle decoding the payload in your application when you retrieve keys from the new instance.
- **The new KeyProtect instances will only be accessible with IAM tokens.** CloudFoundry/UAA tokens will not work with the new instances, and have been deprecated in the legacy instances already. If you are already using IAM tokens in legacy instances, there shouldn't be any changes needed, other than ensuring IAM Access Policies are updated for access to the new KeyProtect instance.
- **You will need to update your application(s) to use the new US-SOUTH region endpoint for KeyProtect.** Other than the IAM and base64 payloads mentioned above, the API remains compatible between legacy and new instances. However the new instances must be accessed through the new US-SOUTH region endpoint, `https://keyprotect.us-south.bluemix.net/`. Generally, this should be a simple change to the host portion of the URL in configuration or the application code. i.e. `https://ibm-key-protect.edge.bluemix.net/api/v2/keys` will become `https://keyprotect.us-south.bluemix.net/api/v2/keys`

For more details on these changes and how to update your application, please check the [Updating your applications](#updating-your-applications) section.

After the migration completes, the client populates your new Key Protect service instance with your migrated encryption keys and creates a `migration.csv` file that shows how the old key IDs map to the migrated keys for easy identification.

## Before you begin

>**Important:** Before you begin the migration process, back up your existing encryption keys to a secure location to ensure you maintain access to your data.

To work with Key Protect keys that are stored in a Cloud Foundry space:

- You must have access to the IBM Cloud account where your Key Protect service instance was initially provisioned.

- You must be assigned the appropriate Cloud Foundry access role to view and retrieve Key Protect resources within your IBM Cloud account. For example, if you are assigned a _Developer_ access role, you can retrieve the Key Protect keys that are stored in a Cloud Foundry space. To learn more about viewing your existing Cloud Foundry access policy, see [Cloud Foundry access](https://console.bluemix.net/docs/iam/cfaccess.html#cfaccess).

To move keys into a new instance of Key Protect:

- You must have a new Key Protect service instance provisioned within your IBM Cloud account. To learn more about creating a new Key Protect service instance, see [Provisioning the service](https://console.bluemix.net/docs/services/key-protect/provision.html#provision).

- New instances of Key Protect use Cloud Identity and Access Management (IAM) for access control. You must be assigned the appropriate Cloud IAM access role to view and create resources within the new Key Protect service instance.  If you are assigned a _Manager_ or _Writer_ Cloud IAM role, you can view and create keys in your new Key Protect service instance. To learn more about viewing your existing Cloud IAM access policy, see [Working with users](https://console.bluemix.net/docs/iam/iamusermanage.html#iamusermanage).

## Setting up the migration client

### Download the latest migration-client 

1. Download the latest release of migration-client for your platform from the [Releases page](https://github.com/locke105/ibm-kms-migration-client/releases)

2. Unzip the release and move into the newly created directory to begin working with the migration client.

    ```sh
    unzip migration-client-linux-amd64.zip -d migration-client
    cd migration-client
    ```

### Gather required information

Gather the Org and Space information of your legacy Key Protect service instance:

1. [Log in to the IBM Cloud console](https://console.bluemix.net).

2. From your user profile, select the account that contains the Cloud Foundry org and space where your legacy Key Protect service instance resides.

3. From the IBM Cloud dashboard, navigate to **Cloud Foundry Services**, and then find the Key Protect service instance that contains the encryption keys that you want to migrate.

    Note the **CF Org** and **CF Space** names that are associated with the legacy Key Protect service. You'll need to set these names as environment variables in a later step.

Gather the service instace name of your new Key Protect service instance:

1. In the IBM Cloud console, select the account and resource group where your new Key Protect service instance resides.

2. From the IBM Cloud dashboard, navigate to **Services**, and then select the Key Protect service instance where you want to migrate your existing encryption keys.

    Note the name that is associated with your Key Protect service instance. You'll need to set this name as an environment variable in a later step.

### Set your environment variables

1. Open the `envs` file that is located in the `migration-client` directory.

2. Set the following environment variables to authenticate to your Key Protect service instances.

    ```sh
    ## Legacy account variables ##
    export CF_ORG="<organization_name>"
    export CF_SPACE="<space_name>"
    
    ## New KP account variables ##
    export KP_SERVICE_INSTANCE_NAME="<instance_name>"
    
    # optional, set this if your new KeyProtect service instance is in a different IBM Cloud Account
    #export KP_ACCOUNT_ID=""
    ```

    Replace `<organization_name>`, `<space_name>`, and `<instance_name>` with the values that you retrieved in the previous step.

3. Save the `envs` file and continue to the next step.


## Migrating your keys

1. Run the _client-wrapper.sh_ script to start migrating keys from your legacy Key Protect service instance.

    ```sh
    ./client-wrapper.sh
    ```

    The client logs into IBM Cloud by using the IBM Cloud CLI plug-in, and then authenticates to each of your Key Protect service instances.

Success! Your existing keys are now migrated into a new Key Protect service instance. You can view how the old key IDs map to the migrated keys by inspecting the `migration.csv` file that is generated after the migration completes. The following table shows an example `migration.csv`file:

| Old key ID                           | New key ID                           |
| ------------------------------------ | ------------------------------------ |
| ef9eb687-b508-45f0-8a3e-1def949bc9f8 | e9ab551c-46fe-448a-8a3c-e0f23dfff362 |

The Key Protect keys that are stored in your Cloud Foundry org and space remain in the legacy Key Protect service instance until you're ready to [permanently delete the keys, and then delete the legacy Key Protect service instance](https://console.bluemix.net/docs/services/key-protect/troubleshooting.html#unable-to-delete-service).

> **Note:** If migration fails in the middle of moving keys, check the _migration.csv_ file to view the keys that were successfully migrated. To resume the migration process, be sure to save the _migration.csv file_, otherwise the client will move the keys again and create duplicate keys in the new instance. If you encounter more errors, check the `migration-client.log` to understand how to proceed.

## Updating your applications

To start using the new Key Protect service instance, update your applications so that they reference the new key IDs and point to the latest Key Protect API endpoint.

### Connecting to the new service API endpoint

Key Protect service instances that exist within a Cloud Foundry org or space use the legacy `https://ibm-key-protect.edge.bluemix.net` endpoint to interact with the Key Protect API. To interact with your new service instance, you must update any references to this endpoint to `https://keyprotect.<region>.bluemix.net`.

For example, if you created your new service instance in the the US South region, use the following endpoint and API headers to browse keys in your service:

```cURL
curl -X GET \
    https://keyprotect.us-south.bluemix.net/api/v2/keys \
    -H 'accept: application/vnd.ibm.collection+json' \
    -H 'authorization: <IAM_token>' \
    -H 'bluemix-instance: <instance_ID>'
```

For more information, see the [Key Protect API reference](https://console.bluemix.net/apidocs/key-protect).

### Handling the base64 encoding requirement

Because new Key Protect service instances allow only base64 encoded key material (the `payload` value in the JSON body) for keys, you must base64 decode keys on retrieval to get the same payload data that you expected previously.

There are many libraries in the various languages that are available for this task. If you want to check your keys by hand (or if you use shell), you can use the base64 utility to decode the retrieved payload.

For example, if you want to decode the base64 encoded payload after you retrieve it from Key Protect, run the following shell command:

```sh
echo <base64_encoded_payload> | base64 -D
```

If you plan to use your new Key Protect service instance to import encryption keys in the future, ensure that you provide key material that is base64 encoded before you upload it to the service.

```sh
echo <payload> | base64
```

## Testing your migration

To ensure that your apps continue to work with the new changes, perform a regression test on your associated applications to complete the migration process.

After your migration and testing is complete, please notify the Key Protect team by sending an email to the Key Protect offering manager at mosbaugh@us.ibm.com.

## Getting help

If you encounter a problem during a migration or in the regression tests of your applications, you can reach out to the IBM Key Protect team for help. Connect with the Key Protect development team by sending an e-mail to Terry Mosbaugh at mosbaugh@us.ibm.com.

To find out more about the latest Key Protect service features, check out the [Key Protect service documentation](https://console.bluemix.net/docs/services/key-protect/index.html).
