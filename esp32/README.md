# Secure Storage of Certificate

This project requires the certificate file `main/components/http_client/include/certs.h`, but we do not store it in the
repository in plain text for security reasons. Below, you’ll find instructions on how to encrypt and decrypt this file.

## Instructions for Encrypting and Decrypting the Certificate File

### Prerequisites

We use `openssl` to encrypt and decrypt the file, which is typically available on most operating systems. If you don’t
have `openssl`, please install it according to your system requirements.

### Step 1: Encrypting the `certs.h` File

1. Place the certificate file at `main/components/http_client/include/certs.h`.
2. Run the following command to encrypt the file:
   ```bash
   openssl enc -aes-256-cbc -salt -in main/components/http_client/include/certs.h -out main/components/http_client/include/certs.h.enc -k <password>
   ```
   Replace <password> with the password you wish to use for encryption.

### Step 2: Decrypting the `certs.h.enc` File

1. To use the certificate, decrypt the file first:
   ```bash
   openssl enc -aes-256-cbc -d -in main/components/http_client/include/certs.h.enc -out main/components/http_client/include/certs.h -k <password>
   ```
   Enter the same password used for encryption.
2. The `certs.h` file will now be available for use in your application.

