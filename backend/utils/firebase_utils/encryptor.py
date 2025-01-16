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


def create_collection(mac_address: str, encryption_key: bytes):
    """
    Zapisuje klucz szyfrowania w Firebase powiązany z MAC adresem urządzenia.

    :param mac_address: MAC adres urządzenia
    :param encryption_key: Klucz szyfrowania
    """
    try:
        device_id = mac_address.replace(":", "")

        db.collection("boards").document(device_id).set({
            "mac_address": mac_address,
            "status": "available",
            "registered_at": None,
            "assigned_to": None,
            "history": [],
        })
        print(f"Klucz szyfrowania zapisany dla urządzenia: {mac_address}")
    except Exception as e:
        print(f"Błąd podczas zapisywania klucza szyfrowania: {e}")
