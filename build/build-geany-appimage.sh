#!/bin/bash
set -e

############################################
# Always run from repository root
############################################

cd "$(dirname "$0")/.."
REPO_ROOT="$PWD"
export REPO_ROOT
echo "Repo root: $REPO_ROOT"

APPDIR="$REPO_ROOT/Geany.AppDir"

# Clean up previous build artifacts
rm -rf "$APPDIR"
rm -f "$REPO_ROOT/Geany-x86_64.AppImage"
rm -f "$REPO_ROOT/geany.conf"
rm -rf "$REPO_ROOT/venv_appimage_builder"

mkdir -p "$APPDIR"
mkdir -p "$APPDIR/usr/lib"

############################################
# Tool Availability Check
############################################

echo "=== Checking Tools ==-"
# Download linuxdeploy if missing
if [ ! -f "$REPO_ROOT/linuxdeploy" ]; then
    echo "Downloading linuxdeploy..."
    wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage -O "$REPO_ROOT/linuxdeploy"
    chmod +x "$REPO_ROOT/linuxdeploy"
fi

# Download appimagetool if missing
if [ ! -f "$REPO_ROOT/appimagetool" ]; then
    echo "Downloading appimagetool..."
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O "$REPO_ROOT/appimagetool"
    chmod +x "$REPO_ROOT/appimagetool"
fi

############################################
# Build Geany 2.1
############################################

echo "=== Building Geany 2.1 ==-"
cd "$REPO_ROOT"

if [ ! -f geany-2.1.tar.bz2 ]; then
    wget -q https://download.geany.org/geany-2.1.tar.bz2
fi

rm -rf geany-2.1
tar xf geany-2.1.tar.bz2

GEANY_DIR="$REPO_ROOT/geany-2.1"
echo "Detected Geany directory: $GEANY_DIR"

# Patch Geany to respect GEANY_PLUGIN_PATH and GEANY_DATA_DIR
cat << 'EOF' > patch_utils.py
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
EOF

python3 patch_utils.py "$GEANY_DIR/src/utils.c"

# AGGRESSIVE Patch for Persistence
cat << 'EOF' > patch_persistence.py
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
EOF

python3 patch_persistence.py "$GEANY_DIR/src/plugins.c"

# AGGRESSIVE Patch for Localization (Main Menu)
cat << 'EOF' > patch_localization.py
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
EOF

python3 patch_localization.py "$GEANY_DIR/src/libmain.c"

# Build Geany
(
    cd "$GEANY_DIR"
    ./configure --prefix=/usr --enable-binreloc --libdir=/usr/lib
    make -j$(nproc)
    
    # Create geany.desktop manually
    cat << EOF_D > geany.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Geany
Exec=geany %F
Icon=geany
Terminal=false
Categories=GTK;Development;IDE;
EOF_D

    make install DESTDIR="$APPDIR"
)

# Build Geany Plugins 2.1
cd "$REPO_ROOT"
if [ ! -f geany-plugins-2.1.tar.bz2 ]; then
    wget -q https://plugins.geany.org/geany-plugins/geany-plugins-2.1.tar.bz2
fi
rm -rf geany-plugins-2.1
tar xf geany-plugins-2.1.tar.bz2
PLUGIN_DIR="$REPO_ROOT/geany-plugins-2.1"

cd "$PLUGIN_DIR"
# Patch for Geany 2.1 compatibility
sed -i 's/sci_get_selected_text_length2/sci_get_selected_text_length/g' addons/src/ao_wrapwords.c
sed -i 's/sci_get_selected_text_length2/sci_get_selected_text_length/g' pretty-printer/src/PluginEntry.c
sed -i 's/sci_get_selected_text_length2/sci_get_selected_text_length/g' scope/src/plugme.c

export PKG_CONFIG_PATH="$APPDIR/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
GLIB_CFLAGS=$(pkg-config --cflags glib-2.0 gtk+-3.0)
export CPPFLAGS="$GLIB_CFLAGS -I$APPDIR/usr/include/geany -I$APPDIR/usr/include/geany/tagmanager -I$APPDIR/usr/include/geany/scintilla"
export LDFLAGS="-L$APPDIR/usr/lib"

./configure --prefix=/usr --libdir=/usr/lib \
    --disable-geanylua --disable-geniuspaste --disable-updatechecker --disable-geanygendoc \
    --disable-lsp --disable-vimode --disable-workbench --disable-projectorganizer \
    --disable-spellcheck --disable-webhelper --disable-markdown

make -j$(nproc)
make install DESTDIR="$APPDIR"

# Localization fallback for plugins
echo "--- Fixing Czech translation for plugins ---"
(
    cd po
    wget -q "https://raw.githubusercontent.com/geany/geany-plugins/master/po/cs.po" -O cs.po || true
    wget -q "https://raw.githubusercontent.com/python/cpython/main/Tools/i18n/msgfmt.py" -O "$REPO_ROOT/msgfmt.py"
    for po_file in *.po; do
        if [ -s "$po_file" ]; then
            lang=$(basename "$po_file" .po)
            mkdir -p "$APPDIR/usr/share/locale/$lang/LC_MESSAGES"
            python3 "$REPO_ROOT/msgfmt.py" -o "$APPDIR/usr/share/locale/$lang/LC_MESSAGES/geany-plugins.mo" "$po_file" || true
        fi
    done
)

# Fixing nested installation
NESTED_PLUGIN_DIR=$(find "$APPDIR" -path "*/usr/lib/geany" -not -path "$APPDIR/usr/lib/geany" | head -n 1)
if [ -n "$NESTED_PLUGIN_DIR" ]; then mv "$NESTED_PLUGIN_DIR"/* "$APPDIR/usr/lib/geany/"; fi
find "$APPDIR" -name "locale" -type d | while read -r loc; do
    if [ "$loc" != "$APPDIR/usr/share/locale" ]; then cp -an "$loc"/* "$APPDIR/usr/share/locale/" || true; fi
done
rm -rf "$APPDIR/home"

# Final Assembly
cd "$REPO_ROOT"
mkdir -p "$APPDIR/usr/lib/x86_64-linux-gnu"
cp /usr/lib/x86_64-linux-gnu/libstdc++.so.6 "$APPDIR/usr/lib/x86_64-linux-gnu/" || true

# Robust GIO Module Copy
mkdir -p "$APPDIR/usr/lib/gio/modules"
GIO_MOD_PATHS=(
    "/usr/lib/x86_64-linux-gnu/gio/modules"
    "/usr/lib64/gio/modules"
    "/usr/lib/gio/modules"
)
for mod_path in "${GIO_MOD_PATHS[@]}"; do
    if [ -d "$mod_path" ]; then
        cp -a "$mod_path"/libgiognutls.so "$APPDIR/usr/lib/gio/modules/" 2>/dev/null || true
        cp -a "$mod_path"/libdconfsettings.so "$APPDIR/usr/lib/gio/modules/" 2>/dev/null || true
    fi
done

if [ -f /usr/bin/gio-querymodules ]; then
    cp /usr/bin/gio-querymodules "$APPDIR/usr/bin/"
    (
        export LD_LIBRARY_PATH="$APPDIR/usr/lib:$LD_LIBRARY_PATH"
        export GIO_MODULE_DIR="$APPDIR/usr/lib/gio/modules"
        "$APPDIR/usr/bin/gio-querymodules" "$APPDIR/usr/lib/gio/modules"
    )
fi

patchelf --set-rpath "\$ORIGIN/../lib" "$APPDIR/usr/bin/geany"
for plugin_so in "$APPDIR/usr/lib/geany"/*.so; do
    if [ -f "$plugin_so" ]; then
        patchelf --set-rpath "\$ORIGIN/.." "$plugin_so"
        patchelf --add-needed libgeany.so.0 "$plugin_so" || true
    fi
done

# Create Definitive AppRun
cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/sh
HERE=$(dirname "$(readlink -f "$0")")
export APPDIR="$HERE"
export PATH="$HERE/usr/bin:$PATH"
export LD_LIBRARY_PATH="$HERE/usr/lib/x86_64-linux-gnu:$HERE/usr/lib:$LD_LIBRARY_PATH"
export XDG_DATA_DIRS="$HERE/usr/share:$XDG_DATA_DIRS"
export GIO_MODULE_DIR="$HERE/usr/lib/gio/modules"
export GEANY_PLUGIN_PATH="$HERE/usr/lib/geany"
export GEANY_DATA_DIR="$HERE/usr/share/geany"
export TEXTDOMAINDIR="$HERE/usr/share/locale"
# Force Czech if translation exists
if [ -d "$HERE/usr/share/locale/cs" ]; then
    export LANG="cs_CZ.UTF-8"
    export LANGUAGE="cs_CZ:cs"
    export LC_ALL="cs_CZ.UTF-8"
fi
exec "$HERE/usr/bin/geany" "$@"
EOF
chmod +x "$APPDIR/AppRun"

./linuxdeploy --appdir "$APPDIR" -e "$APPDIR/usr/bin/geany" \
    --exclude-library libwebkit2gtk-4.0.so.37 --exclude-library libjavascriptcoregtk-4.0.so.18 \
    --exclude-library libicuuc.so.72 --exclude-library libicui18n.so.72
./appimagetool "$APPDIR" "$REPO_ROOT/Geany-x86_64.AppImage"
