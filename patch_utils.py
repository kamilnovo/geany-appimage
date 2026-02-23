import sys
import os

path = sys.argv[1]
with open(path, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    new_lines.append(line)
    if 'static const gchar *resdirs[RESOURCE_DIR_COUNT] = {NULL};' in line:
        new_lines.append('        if (type == RESOURCE_DIR_PLUGIN) { const gchar *env_path = g_getenv("GEANY_PLUGIN_PATH"); if (env_path != NULL) return env_path; }\n')
        new_lines.append('        if (type == RESOURCE_DIR_DATA) { const gchar *env_path = g_getenv("GEANY_DATA_DIR"); if (env_path != NULL) return env_path; }\n')

with open(path, 'w') as f:
    f.writelines(new_lines)
