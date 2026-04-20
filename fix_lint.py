import os
import re

directory = 'd:/sedya_mobile/lib/ui/screens'

for filename in os.listdir(directory):
    if filename.endswith(".dart"):
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r') as file:
            content = file.read()

        # Fix super parameters: `const ClassName({Key? key}) : super(key: key);` -> `const ClassName({super.key});`
        content = re.sub(r'const (\w+)\(\{Key\? key([^}]*)\}\) : super\(key: key\);', r'const \1({super.key\2});', content)

        # Fix withOpacity
        content = content.replace('.withOpacity(', '.withValues(alpha: ')

        # Fix value in DropdownButtonFormField
        content = content.replace('value: project?.phase ?? \'Planning\',', 'initialValue: project?.phase ?? \'Planning\',')

        # Fix activeColor in SwitchListTile
        content = content.replace('activeColor: AppColors.primary,', 'activeThumbColor: AppColors.primary,')

        with open(filepath, 'w') as file:
            file.write(content)

print("Files updated")
