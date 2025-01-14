import firebase_admin
from cryptography.fernet import Fernet
from firebase_admin import credentials, firestore

cred = credentials.Certificate(
    "mqtt_firebase_connection_wrapper/smart-lighting-system-firebase-admin-sdk-credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("Connected to Firebase successfully!")


def generate_key() -> bytes:
    """
    Generuje klucz szyfrowania.
    """
    return Fernet.generate_key()


def encrypt_data(data: str, key: bytes) -> str:
    """
    Szyfruje dane przy użyciu klucza.

    :param data: Dane do zaszyfrowania
    :param key: Klucz szyfrowania
    :return: Zaszyfrowane dane jako string
    """
    cipher = Fernet(key)
    encrypted_data = cipher.encrypt(data.encode())
    return encrypted_data.decode()


def decrypt_data(encrypted_data: str, key: bytes) -> bytes:
    """
    Deszyfruje dane przy użyciu klucza.

    :param encrypted_data: Zaszyfrowane dane jako string
    :param key: Klucz szyfrowania
    :return: Odszyfrowane dane
    """
    cipher = Fernet(key)
    decrypted_data = cipher.decrypt(encrypted_data.encode())
    return decrypted_data


def store_encryption_key(mac_address: str, encryption_key: bytes):
    """
    Zapisuje klucz szyfrowania w Firebase powiązany z MAC adresem urządzenia.

    :param mac_address: MAC adres urządzenia
    :param encryption_key: Klucz szyfrowania
    """
    try:
        device_id = mac_address.replace(":", "")

        db.collection("devices").document(device_id).set({
            "mac_address": mac_address,
            "encryption_key": encryption_key.decode(),
        })
        print(f"Klucz szyfrowania zapisany dla urządzenia: {mac_address}")
    except Exception as e:
        print(f"Błąd podczas zapisywania klucza szyfrowania: {e}")
