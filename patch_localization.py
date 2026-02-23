import sys
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# Force bindtextdomain to use TEXTDOMAINDIR if set
fix = r'''
    const gchar *env_locdir = g_getenv("TEXTDOMAINDIR");
    if (env_locdir != NULL) locale_dir = env_locdir;
    (void) bindtextdomain(package, locale_dir);
'''
content = content.replace('(void) bindtextdomain(package, locale_dir);', fix)

with open(path, 'w') as f:
    f.write(content)
