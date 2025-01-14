from cryptography.fernet import Fernet


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
