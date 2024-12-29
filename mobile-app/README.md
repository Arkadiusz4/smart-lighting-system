# mobile_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### Keys

We have sensitive keys that are hashed and that needs to be decrypted on your machine in order for you to be able to
build an application or even deploy to production. To decrypt the keys, run where you replace `<password>` with our
secure password.

#### Encrypting files

Run the following command to encrypt files:

```bash
openssl enc -aes-256-cbc -salt -in android/app/google-services.json -out android/app/google-services.json.enc -k <password>
openssl enc -aes-256-cbc -salt -in ios/Runner/GoogleService-Info.plist -out ios/Runner/GoogleService-Info.plist.enc -k <password>
```

In the event you will have to encrypt a file, again replacing `<password>` with our secure password:

```bash
openssl enc -aes-256-cbc -salt -in INPUT_FILE -out OUTPUT_FILE -k <password> -a
```

#### Decrypting files

Run the following command to decrypt files:

```bash
openssl enc -d -aes-256-cbc -in android/app/google-services.json.enc -out android/app/google-services.json -k <password>
openssl enc -d -aes-256-cbc -in ios/Runner/GoogleService-Info.plist.enc -out ios/Runner/GoogleService-Info.plist.json -k <password>
```

> **Note**: Never commit the decrypted files directly to the repository.
