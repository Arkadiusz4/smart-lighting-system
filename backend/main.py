from utils.qr_code_generator.qr_code_generator import generate_qr_code
from utils.firebase_utils.encryptor import generate_key, create_collection

if __name__ == "__main__":
    encryption_key = generate_key()

    # mac_address = "F0:F5:BD:4A:A6:2C"
    mac_address = "AA:BB:CC:DD:EE:FF"
    output_path = "output/esp32_test.png"

    generate_qr_code(mac_address, output_path)

    create_collection(mac_address, encryption_key)

    print(f"Klucz szyfrowania zapisany w Firebase dla MAC adresu: {mac_address}")
