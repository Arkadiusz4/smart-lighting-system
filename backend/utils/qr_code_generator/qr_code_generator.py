import qrcode
import random
import string


def generate_qr_code(mac_address: str, output_path: str):
    """
    Generuje kod QR zawierający zaszyfrowane dane.

    :param mac_address: MAC adres urządzenia
    :param output_path: Ścieżka do pliku wyjściowego
    """
    additional_data = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

    plain_data = f"MAC:{mac_address};TOKEN:{additional_data}"

    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(plain_data)
    qr.make(fit=True)

    img = qr.make_image(fill='black', back_color='white')
    img.save(output_path)
    print(f"QR kod wygenerowany z danymi: {plain_data}")
