import os, json

history_dir = os.path.expanduser(r'~\AppData\Roaming\Code\User\History')
found = []

if os.path.exists(history_dir):
    for root, dirs, files in os.walk(history_dir):
        if 'entries.json' in files:
            try:
                with open(os.path.join(root, 'entries.json'), 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    
                    res = data.get('resource', '')
                    if 'armory_screen.dart' in res:
                        print(f"ARMORY at {root}")
                        found.append((root, data))
                    elif 'challenge_detail_screen.dart' in res:
                        print(f"DETAIL at {root}")
                        found.append((root, data))
            except Exception as e:
                pass

with open('history_output.txt', 'w', encoding='utf-8') as out:
    for r, d in found:
        out.write(f"{r}\n{json.dumps(d, indent=2)}\n\n")
    out.write("Done.")
