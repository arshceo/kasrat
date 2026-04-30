import os, json

history_dir = os.path.expanduser(r'~\AppData\Roaming\Code\User\History')
found_armory = []
found_detail = []

if os.path.exists(history_dir):
    for root, dirs, files in os.walk(history_dir):
        if 'entries.json' in files:
            try:
                with open(os.path.join(root, 'entries.json'), 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    
                    res = data.get('resource', '')
                    if 'armory_screen.dart' in res:
                        print(f"Found armory_screen.dart history at: {root}")
                        for entry in data.get('entries', []):
                            print(f"  Entry: {entry.get('id')}")
                        found_armory.append(root)
                    elif 'challenge_detail_screen.dart' in res:
                        print(f"Found challenge_detail_screen.dart history at: {root}")
                        for entry in data.get('entries', []):
                            print(f"  Entry: {entry.get('id')}")
                        found_detail.append(root)
            except Exception as e:
                pass

print("Done scanning.")
