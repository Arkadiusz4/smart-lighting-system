from utils.qr_code_generator.qr_code_generator import generate_qr_code
from utils.crypto_utils.encryptor import generate_key, store_encryption_key

if __name__ == "__main__":
    # Generowanie klucza szyfrowania
    encryption_key = generate_key()

    # Przykładowe dane
    mac_address = "AA:BB:CC:DD:EE:FF"
    output_path = "output/device_qr.png"

    # Generowanie kodu QR
    generate_qr_code(mac_address, output_path, encryption_key)

    # Zapisanie klucza w Firebase
    store_encryption_key(mac_address, encryption_key)

    print(f"Klucz szyfrowania zapisany w Firebase dla MAC adresu: {mac_address}")
