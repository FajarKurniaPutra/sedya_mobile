import os
import re

lib_dir = r"d:\sedya_mobile\lib"

# Regex pattern to match const followed by common Flutter widget names
pattern = re.compile(r'const\s+(TextStyle|Icon|BoxDecoration|InputDecoration|BorderSide|Divider|Text|AppBarTheme|Row|Column|Center|Container|SizedBox)\b')

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to remove 'const' if the block it applies to contains 'AppColors.'
    # A simple line-by-line approach:
    lines = content.split('\n')
    modified = False
    
    # Simple heuristic: remove 'const ' if the line contains 'const ' and 'AppColors.'
    for i in range(len(lines)):
        line = lines[i]
        if 'const ' in line and 'AppColors.' in line:
            # specifically remove 'const ' before widgets
            lines[i] = re.sub(r'const\s+(TextStyle|Icon|BoxDecoration|InputDecoration|BorderSide|Divider|Text|AppBarTheme|Row|Column|Center|Container|SizedBox)\b', r'\1', line)
            modified = True
            
        # Handle multi-line const where const is on one line and AppColors is on the next few lines
        # We look back up to 3 lines if we find AppColors
        if 'AppColors.' in line:
            for j in range(max(0, i-3), i+1):
                if 'const ' in lines[j] and j != i:
                    old_len = len(lines[j])
                    lines[j] = re.sub(r'const\s+(TextStyle|Icon|BoxDecoration|InputDecoration|BorderSide|Divider|Text|AppBarTheme|Row|Column|Center|Container|SizedBox)\b', r'\1', lines[j])
                    if len(lines[j]) != old_len:
                        modified = True

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        print(f"Modified: {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Done")
