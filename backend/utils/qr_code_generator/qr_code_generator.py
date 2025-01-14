import qrcode
import random
import string
from utils.crypto_utils.encryptor import encrypt_data


def generate_qr_code(mac_address: str, output_path: str, encryption_key: bytes):
    """
    Generuje kod QR zawierający zaszyfrowane dane.

    :param mac_address: MAC adres urządzenia
    :param output_path: Ścieżka do pliku wyjściowego
    :param encryption_key: Klucz szyfrowania
    """
    # Generowanie losowego tokenu
    additional_data = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

    # Dane do zakodowania
    plain_data = f"MAC:{mac_address};TOKEN:{additional_data}"
    encrypted_data = encrypt_data(plain_data, encryption_key)

    # Generowanie kodu QR
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(encrypted_data)
    qr.make(fit=True)

    # Tworzenie obrazu QR
    img = qr.make_image(fill='black', back_color='white')

    # Zapisanie obrazu do pliku
    img.save(output_path)

    print(f"QR kod wygenerowany z zaszyfrowanymi danymi: {encrypted_data}")
