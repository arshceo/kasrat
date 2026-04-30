import os

search_dir = os.path.expanduser(r'~\AppData\Roaming\Code\User\History')
found = []

if os.path.exists(search_dir):
    for root, dirs, files in os.walk(search_dir):
        if 'entries.json' in files:
            with open(os.path.join(root, 'entries.json'), 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                if 'armory_screen.dart' in content or 'challenge_detail_screen.dart' in content:
                    found.append(root)

with open('history_search.txt', 'w', encoding='utf-8') as out:
    out.write("\n".join(found))
    if not found:
        out.write("No matches found.")
