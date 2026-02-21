#!/bin/bash
set -e

# === CONFIG ===
GEANY_VERSION="2.0"
PLUGINS_VERSION="2.0"
APPDIR="Geany.AppDir"

echo "=== Installing build dependencies ==="
sudo apt update
sudo apt install -y \
    build-essential autoconf automake libtool pkg-config \
    libgtk-3-dev libxml2-dev intltool wget git fuse libfuse2 \
    libvte-2.91-dev libenchant-2-dev libaspell-dev

echo "=== Cleaning previous build ==="
rm -rf $APPDIR geany-$GEANY_VERSION geany-plugins-$PLUGINS_VERSION

echo "=== Downloading Geany $GEANY_VERSION ==="
wget https://download.geany.org/geany-$GEANY_VERSION.tar.bz2
tar xf geany-$GEANY_VERSION.tar.bz2

echo "=== Downloading Geany Plugins $PLUGINS_VERSION ==="
wget https://github.com/geany/geany-plugins/archive/refs/tags/$PLUGINS_VERSION.tar.gz
tar xf $PLUGINS_VERSION.tar.gz

echo "=== Preparing AppDir ==="
mkdir -p $APPDIR/usr

echo "=== Building Geany ==="
cd geany-$GEANY_VERSION
./configure --prefix=/usr
make -j$(nproc)
make install DESTDIR=../$APPDIR
cd ..

echo "=== Applying Color Preview patch ==="
patch -p1 -d geany-plugins-$PLUGINS_VERSION < build/patches/colorpreview-bigger-icons.patch || true

echo "=== Building Plugins ==="
cd geany-plugins-$PLUGINS_VERSION
./autogen.sh

./configure --prefix=/usr \
    --enable-addons \
    --enable-autoclose \
    --enable-codenav \
    --enable-commander \
    --enable-debugger \
    --enable-geanydoc \
    --enable-geanyextrasel \
    --enable-geanyinsertnum \
    --enable-geanylua \
    --enable-geanymacro \
    --enable-geanyminiscript \
    --enable-geanynumberedbookmarks \
    --enable-geanypg \
    --enable-geanyprj \
    --enable-geanyvc \
    --enable-git-changebar \
    --enable-keyrecord \
    --enable-lineoperations \
    --enable-lipsum \
    --enable-markdown \
    --enable-multiterm \
    --enable-overview \
    --enable-pohelper \
    --enable-pretty-printer \
    --enable-projectorganizer \
    --enable-sendmail \
    --enable-shiftcolumn \
    --enable-spellcheck \
    --enable-tableconvert \
    --enable-treebrowser \
    --enable-vimode \
    --enable-xmlsnippets \
    --enable-colorpreview

make -j$(nproc)
make install DESTDIR=../$APPDIR
cd ..

echo "=== Generating default Geany config ==="

# Spustíme Geany jednou, aby vytvořil defaultní konfiguraci
mkdir -p $APPDIR/config
GEANY_CONFIG_DIR="$APPDIR/config" $APPDIR/usr/bin/geany --quit 2>/dev/null || true

echo "=== Applying preset theme and enabling TreeBrowser plugin ==="

# Nastavíme theme Darcula
sed -i 's/^color_scheme=.*/color_scheme=darcula.conf/' $APPDIR/config/geany.conf

# Zapneme plugin TreeBrowser
mkdir -p $APPDIR/config/plugins
echo "[General]" > $APPDIR/config/plugins/treebrowser.conf
echo "show_hidden=false" >> $APPDIR/config/plugins/treebrowser.conf
echo "follow_current=false" >> $APPDIR/config/plugins/treebrowser.conf

# Aktivace pluginu v geany.conf
if ! grep -q "treebrowser" $APPDIR/config/geany.conf; then
    sed -i 's/^active_plugins=.*/active_plugins=treebrowser.so/' $APPDIR/config/geany.conf
fi

echo "=== Installing Geany color schemes ==="
wget https://github.com/geany/geany-themes/archive/refs/heads/master.zip -O geany-themes.zip
unzip geany-themes.zip
mkdir -p $APPDIR/usr/share/geany/colorschemes
cp geany-themes-master/colorschemes/*.conf $APPDIR/usr/share/geany/colorschemes/

echo "=== Adding desktop file and icon ==="
mkdir -p $APPDIR/usr/share/applications
mkdir -p $APPDIR/usr/share/icons/hicolor/256x256/apps

cp geany-$GEANY_VERSION/data/geany.desktop $APPDIR/usr/share/applications/
cp geany-$GEANY_VERSION/data/geany.png $APPDIR/usr/share/icons/hicolor/256x256/apps/


echo "=== Creating AppRun (fully portable mode) ==="

cat > $APPDIR/AppRun << 'EOF'
#!/bin/bash

# Fully portable Geany
export GEANY_CONFIG_DIR="$APPDIR/config"

# Ensure all subdirectories exist
mkdir -p "$GEANY_CONFIG_DIR"
mkdir -p "$GEANY_CONFIG_DIR/snippets"
mkdir -p "$GEANY_CONFIG_DIR/templates"
mkdir -p "$GEANY_CONFIG_DIR/plugins"
mkdir -p "$GEANY_CONFIG_DIR/filedefs"

# Run Geany
exec "$APPDIR/usr/bin/geany" "$@"
EOF

chmod +x $APPDIR/AppRun

echo "=== Generating default Geany config ==="

# Spustíme Geany jednou, aby vytvořil defaultní konfiguraci
mkdir -p $APPDIR/config
GEANY_CONFIG_DIR="$APPDIR/config" $APPDIR/usr/bin/geany --quit 2>/dev/null || true

echo "=== Applying full Pro Edition configuration ==="

###############################################
# geany.conf – hlavní konfigurace
###############################################
cat > $APPDIR/config/geany.conf << 'EOF'
[geany]
color_scheme=darcula.conf
editor_font=JetBrains Mono 11
use_font_from_theme=false

# Sidebar
sidebar_visible=true
sidebar_position=left
sidebar_width=260

# Toolbar
toolbar_icon_size=24
toolbar_show_text=false

# Editor behavior
indent_mode=2
indent_width=4
use_tabs=false
auto_indent=true
line_wrapping=false
show_line_numbers=true
highlight_current_line=true
brace_match=true
use_tab_to_indent=true
show_whitespace=false
show_line_endings=false
show_indent_guides=true

# Minimap
show_minimap=true

# Encoding & line endings
default_newline_type=0
default_encoding=UTF-8

# Session
save_session=true
load_session=true

# Plugins
active_plugins=treebrowser.so;colorpreview.so;geanyextrasel.so;lineoperations.so;multiterm.so;markdown.so
EOF

###############################################
# TreeBrowser plugin config
###############################################
cat > $APPDIR/config/plugins/treebrowser.conf << 'EOF'
[General]
show_hidden=false
follow_current=true
expand_root=true
show_bookmarks=false
EOF

###############################################
# Snippets
###############################################
cat > $APPDIR/config/snippets.conf << 'EOF'
[Default]
for=for (${cursor}) {\n}
if=if (${cursor}) {\n}
elif=else if (${cursor}) {\n}
else=else {\n}
while=while (${cursor}) {\n}
switch=switch (${cursor}) {\n}
case=case ${cursor}:\nbreak;
EOF

###############################################
# Templates
###############################################
mkdir -p $APPDIR/config/templates

cat > $APPDIR/config/templates/filetypes.c << 'EOF'
#include <stdio.h>

int main(int argc, char *argv[]) {
    ${cursor}
    return 0;
}
EOF

cat > $APPDIR/config/templates/filetypes.python << 'EOF'
#!/usr/bin/env python3

def main():
    ${cursor}

if __name__ == "__main__":
    main()
EOF

cat > $APPDIR/config/templates/filetypes.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>${cursor}</title>
</head>
<body>

</body>
</html>
EOF

###############################################
# Toolbar layout
###############################################
cat > $APPDIR/config/ui_toolbar.xml << 'EOF'
<?xml version="1.0"?>
<ui>
  <toolbar name="toolbar">
    <toolitem action="FileNew" />
    <toolitem action="FileOpen" />
    <toolitem action="FileSave" />
    <separator />
    <toolitem action="EditUndo" />
    <toolitem action="EditRedo" />
    <separator />
    <toolitem action="BuildCompile" />
    <toolitem action="BuildExecute" />
    <separator />
    <toolitem action="SearchFind" />
  </toolbar>
</ui>
EOF

###############################################
# Filedefs – vylepšené zvýraznění
###############################################
mkdir -p $APPDIR/config/filedefs

cat > $APPDIR/config/filedefs/filetypes.css << 'EOF'
# ColorPreview-friendly CSS
color=#ff0000
background-color=#000000
border-color=#00ff00
EOF

cat > $APPDIR/config/filedefs/filetypes.c << 'EOF'
# Highlight TODO
keyword=TODO
EOF

cat > $APPDIR/config/filedefs/filetypes.python << 'EOF'
# Highlight f-strings
string_f=1
EOF

echo "=== Full Pro Edition configuration applied ==="

echo "=== Downloading AppImage tool ==="
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

echo "=== Building AppImage ==="
./appimagetool-x86_64.AppImage $APPDIR

echo "======================================="
echo " AppImage build complete!"
echo "======================================="

