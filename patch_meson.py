import sys
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

import re
# Match i18n.merge_file(...) across multiple lines including nested parens
# This is a bit rough but should work for typical meson files
pattern = r'i18n\.merge_file\s*\((?:[^)(]+|\((?:[^)(]+|\([^)(]*\))*\))*\)'
new_content = re.sub(pattern, "find_program('true')", content, flags=re.DOTALL)

with open(path, 'w') as f:
    f.write(new_content)
