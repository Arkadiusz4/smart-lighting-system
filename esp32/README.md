# IoT Lighting Control System for ESP32-S3

This project implements a secure IoT lighting control system using the ESP32-S3 microcontroller. The setup includes a
Makefile to simplify build, flash, and monitor steps, alongside secure handling of SSL certificates for encrypted HTTP
communication.

---

## Table of Contents

1. [Project overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Setting up ESP-IDF](#setting-up-esp-idf)
4. [Secure storage of certificate](#secure-storage-of-certificate)
    * [Encrypting the certs.h file](#encrypting-the-certsh-file)
    * [Decrypting the certs.h.enc file](#decrypting-the-certshenc-file)
5. [Using the Makefile](#using-the-makefile)
    * [Makefile targets](#makefile-targets)
6. [Example workflow](#example-workflow)
7. [Color-coded output](#color-coded-output)

---

## Project Overview

This project uses the ESP32-S3 microcontroller to manage and control lighting in a secure IoT environment. The ESP32-S3
communicates with a remote server over HTTPS, utilizing encrypted SSL certificates for secure data transmission. The
project is designed for seamless setup and deployment using a Makefile, which handles initialization, building,
flashing, and monitoring processes.

---

## Prerequisites

* **ESP32-S3 development board**
* **USB cable** for programming the ESP32
* **ESP-IDF** (Espressif IoT Development Framework)
* **OpenSSL** for encrypting and decrypting the certificate file

---

## Setting up ESP-IDF

1. **Download ESP-IDF**: Follow the
   official [ESP-IDF setup guide](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/get-started/index.html) to
   download and install ESP-IDF.
2. **Set up the environment**: Each time you start a new terminal session, set up the ESP-IDF environment by running:
   ```bash
   source /path/to/esp-idf/export.sh
   ```
3. Configure ESP32 Device: Ensure the ESP32-S3 device is properly connected to your system. Identify the serial port to
   use (e.g., `/dev/cu.usbmodemXYZ` on macOS or `/dev/ttyUSB0` on Linux).

---

## Secure storage of certificate

To ensure secure communication, this project requires a certificate file (`certs.h`) stored at
`main/components/http_client/include/certs.h`. For security, we encrypt this file and do not store it in plain text in
the
repository. Follow these steps to securely manage this file.

### Encrypting the certs.h file

1. Place the certificate file at main/components/http_client/include/certs.h.
2. Run the following command to encrypt it:
   ```bash
   openssl enc -aes-256-cbc -salt -in main/components/http_client/include/certs.h -out
   main/components/http_client/include/certs.h.enc -k <password>
   ```
   Replace `<password>` with a secure password. The resulting `certs.h.enc` file is now encrypted and safe to store in
   the
   repository.

### Decrypting the certs.h.enc file

1. To use the certificate, decrypt it by running:
   ```bash
   openssl enc -aes-256-cbc -d -in main/components/http_client/include/certs.h.enc -out
   main/components/http_client/include/certs.h -k <password>
   ```

   Use the same password entered during encryption. The decrypted `certs.h` file will be created
   in `main/components/http_client/include/` and can now be accessed by the application.

   > **Note**: Never commit the decrypted `certs.h` file directly to the repository.

---

## Using the Makefile

The Makefile simplifies building, flashing, and monitoring processes for this project, helping you manage the ESP32-S3
firmware more efficiently.

### Makefile Variables

Update these variables as needed to match your environment:

* `IDF_PATH`: Path to the ESP-IDF installation.
* `PORT`: Serial port connected to the ESP32.
* `BAUD`: Baud rate for flashing.
* `TARGET`: Target ESP device (e.g., `esp32s3`).

#### Sample Configuration in the Makefile:

```makefile
IDF_PATH := /path/to/esp/esp-idf
PORT := /dev/cu.usbmodem21101
BAUD := 115200
TARGET := esp32s3
```

### Makefile targets

* **init**: Sets up the ESP-IDF environment and configures the target board.
   ```bash
   make init
   ```

* **build**: Compiles the project.
  ```bash
  make build
  ```

* **flash**: Erases the flash memory, flashes the firmware, and starts the monitor.
    ``` bash
  make flash
  ```

* **erase**: Erases only the flash memory.
    ```bash
  make erase
  ```

* **build-flash**: Builds the project, erases the flash, flashes firmware, and starts the monitor.
  ```bash
  make build-flash
  ```

* **monitor**: Opens the serial monitor to view ESP32 logs.
  ```bash
  make monitor
  ```

* **all**: Executes the full setup—build, erase flash, flash firmware, and monitor.
  ```bash
  make all
  ```

---

## Example workflow

### Initial Setup and Full Build

For a complete workflow, use the following commands:

```bash
make init
make all
```

### Subsequent Builds and Flashes

After the initial setup, you can simplify with:

```bash
make flash
```

---

## Color-coded output

The Makefile provides color-coded output for easier identification of each step:

* **Blue**: Initialization and flashing.
* **Yellow**: Erase flash status.
* **Green**: Successful task completion.

This makes it easy to follow the process visually during development and debugging.
