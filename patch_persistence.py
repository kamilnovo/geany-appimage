import sys
path = sys.argv[1]
with open(path, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if 'if (!EMPTY(fname) && g_file_test(fname, G_FILE_TEST_EXISTS))' in line:
        new_lines.append('                        /* Persistence Fix: if absolute path fails, try basename in system plugin dir */\n')
        new_lines.append('                        if (!EMPTY(fname) && !g_file_test(fname, G_FILE_TEST_EXISTS))\n')
        new_lines.append('                        {\n')
        new_lines.append('                            gchar *bn = g_path_get_basename(fname);\n')
        new_lines.append('                            const gchar *sys_dir = g_getenv("GEANY_PLUGIN_PATH");\n')
        new_lines.append('                            if (sys_dir != NULL) {\n')
        new_lines.append('                                gchar *new_fname = g_build_filename(sys_dir, bn, NULL);\n')
        new_lines.append('                                if (g_file_test(new_fname, G_FILE_TEST_EXISTS)) {\n')
        new_lines.append('                                    g_free(active_plugins_pref[i]);\n')
        new_lines.append('                                    active_plugins_pref[i] = new_fname;\n')
        new_lines.append('                                    fname = active_plugins_pref[i];\n')
        new_lines.append('                                } else g_free(new_fname);\n')
        new_lines.append('                            }\n')
        new_lines.append('                            g_free(bn);\n')
        new_lines.append('                        }\n')
    new_lines.append(line)

with open(path, 'w') as f:
    f.writelines(new_lines)
