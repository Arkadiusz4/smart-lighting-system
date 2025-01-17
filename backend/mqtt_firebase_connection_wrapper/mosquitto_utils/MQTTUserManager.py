import subprocess


class MQTTUserManager:
    def __init__(self, passwd_file):
        self.passwd_file = passwd_file

    def add_or_update_user(self, username, password):
        try:
            result = subprocess.run(
                ["mosquitto_passwd", "-b", self.passwd_file, username, password],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                print(f"Użytkownik '{username}' został dodany/aktualizowany.")
            else:
                print(f"Błąd podczas dodawania/aktualizacji użytkownika: {result.stderr}")
        except Exception as e:
            print(f"Wystąpił wyjątek: {e}")
