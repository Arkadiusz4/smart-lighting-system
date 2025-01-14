### Keys

We have sensitive keys that are hashed and that needs to be decrypted on your machine in order for you to be able to
build an application or even deploy to production. To decrypt the keys, run where you replace `<password>` with our
secure password.

#### Encrypting files

Run the following command to encrypt files:

```bash
openssl enc -aes-256-cbc -salt -in mqtt_firebase_connection_wrapper/smart-lighting-system-firebase-admin-sdk-credentials.json -out mqtt_firebase_connection_wrapper/smart-lighting-system-firebase-admin-sdk-credentials.json.enc -k <password>
```

In the event you will have to encrypt a file, again replacing `<password>` with our secure password:

```bash
openssl enc -aes-256-cbc -salt -in INPUT_FILE -out OUTPUT_FILE -k <password> -a
```

#### Decrypting files

Run the following command to decrypt files:

```bash
openssl enc -d -aes-256-cbc -in mqtt_firebase_connection_wrapper/smart-lighting-system-firebase-admin-sdk-credentials.json.enc -out mqtt_firebase_connection_wrapper/smart-lighting-system-firebase-admin-sdk-credentials.json -k <password>
```

> **Note**: Never commit the decrypted files directly to the repository.
