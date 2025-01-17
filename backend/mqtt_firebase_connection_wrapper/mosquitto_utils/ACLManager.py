import os


class ACLManager:
    def __init__(self, acl_file):
        self.acl_file = acl_file

    def add_or_update_rule(self, username, topic, permission="readwrite"):
        try:
            if os.path.exists(self.acl_file):
                with open(self.acl_file, "r") as file:
                    lines = file.readlines()
            else:
                lines = []

            user_line = f"user {username}\n"
            topic_line = f"topic {permission} {topic}\n"

            updated = False
            new_lines = []
            skip_next = False
            for i, line in enumerate(lines):
                if line.strip() == user_line.strip():
                    new_lines.append(line)
                    j = i + 1
                    while j < len(lines) and not lines[j].startswith("user"):
                        if lines[j].strip().endswith(topic):
                            new_lines.append(topic_line)
                            updated = True
                            skip_next = True
                        else:
                            new_lines.append(lines[j])
                        j += 1
                    continue

                if skip_next:
                    skip_next = False
                    continue
                new_lines.append(line)

            if not any(user_line.strip() == l.strip() for l in new_lines):
                new_lines.append(user_line)
            if not updated:
                new_lines.append(topic_line)

            with open(self.acl_file, "w") as file:
                file.writelines(new_lines)

            print(f"Reguła ACL dla użytkownika '{username}' na temat '{topic}' została dodana/aktualizowana.")
        except Exception as e:
            print(f"Wystąpił wyjątek podczas modyfikacji ACL: {e}")
