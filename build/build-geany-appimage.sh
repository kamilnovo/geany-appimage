#!/bin/bash
set -e

# === CONFIG ===
GEANY_VERSION="2.0"
PLUGINS_VERSION="2.0"
APPDIR="$PWD/Geany.AppDir"   # ABSOLUTNÍ cesta
PREFIX="$APPDIR/usr"

echo "=== Installing build dependencies ==="
sudo apt update
sudo apt install -y \
    build-essential autoconf automake libtool pkg-config \
    libgtk-3-dev libxml2-dev intltool wget git fuse libfuse2 \
    libvte-2.91-dev libenchant-2-dev libaspell-dev unzip zsync

echo "=== Cleaning previous build ==="
rm -rf "$APPDIR" geany-$GEANY_VERSION geany-plugins-$PLUGINS_VERSION
mkdir -p "$PREFIX"

echo "=== Downloading Geany $GEANY_VERSION ==="
wget https://download.geany.org/geany-$GEANY_VERSION.tar.bz2
tar xf geany-$GEANY_VERSION.tar.bz2

echo "=== Downloading Geany Plugins $PLUGINS_VERSION ==="
wget https://github.com/geany/geany-plugins/archive/refs/tags/$PLUGINS_VERSION.tar.gz
tar xf $PLUGINS_VERSION.tar.gz

echo "=== Building Geany ==="
cd geany-$GEANY_VERSION

./configure --prefix=/usr
make -j$(nproc)

# ABSOLUTNÍ DESTDIR
make install DESTDIR="$APPDIR"

cd ..

echo "=== Applying Color Preview patch ==="
patch -p1 -d geany-plugins-$PLUGINS_VERSION < build/patches/colorpreview-bigger-icons.patch || true

echo "=== Building Plugins ==="
cd geany-plugins-$PLUGINS_VERSION

# 🔥 TADY JE KRITICKÁ OPRAVA
export PKG_CONFIG_PATH="$APPDIR/usr/lib/pkgconfig"

./autogen.sh

./configure --prefix=/usr \
    --enable-colorpreview \
    --enable-treebrowser \
    --enable-lineoperations \
    --enable-geanymacro \
    --enable-geanyminiscript \
    --enable-geanynumberedbookmarks \
    --enable-git-changebar \
    --enable-keyrecord \
    --enable-overview \
    --enable-pretty-printer \
    --enable-projectorganizer \
    --enable-shiftcolumn \
    --enable-tableconvert \
    --enable-xmlsnippets

make -j$(nproc)

# ABSOLUTNÍ DESTDIR
make install DESTDIR="$APPDIR"

cd ..

echo "=== Installing Geany color schemes ==="
wget https://github.com/geany/geany-themes/archive/refs/heads/master.zip -O geany-themes.zip
unzip geany-themes.zip
mkdir -p "$PREFIX/share/geany/colorschemes"
cp geany-themes-master/colorschemes/*.conf "$PREFIX/share/geany/colorschemes/"

echo "=== Adding desktop file and icon ==="
mkdir -p "$PREFIX/share/applications"
mkdir -p "$PREFIX/share/icons/hicolor/256x256/apps"

cp geany-$GEANY_VERSION/data/geany.desktop "$PREFIX/share/applications/"
cp geany-$GEANY_VERSION/data/geany.png "$PREFIX/share/icons/hicolor/256x256/apps/"

echo "=== Creating AppRun (portable mode) ==="

cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export GEANY_CONFIG_DIR="$HERE/config"
mkdir -p "$GEANY_CONFIG_DIR"
exec "$HERE/usr/bin/geany" "$@"
EOF

chmod +x "$APPDIR/AppRun"

echo "=== Creating portable configuration ==="

mkdir -p "$APPDIR/config"
mkdir -p "$APPDIR/config/plugins"
mkdir -p "$APPDIR/config/templates"
mkdir -p "$APPDIR/config/filedefs"

cat > "$APPDIR/config/geany.conf" << 'EOF'
[geany]
color_scheme=darcula.conf
editor_font=JetBrains Mono 11
use_font_from_theme=false
sidebar_visible=true
sidebar_position=left
sidebar_width=260
toolbar_icon_size=24
toolbar_show_text=false
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
show_minimap=true
default_newline_type=0
default_encoding=UTF-8
save_session=true
load_session=true
active_plugins=treebrowser.so;colorpreview.so;geanyextrasel.so;lineoperations.so;multiterm.so;markdown.so
EOF

cat > "$APPDIR/config/plugins/treebrowser.conf" << 'EOF'
[General]
show_hidden=false
follow_current=true
expand_root=true
show_bookmarks=false
EOF

cat > "$APPDIR/config/snippets.conf" << 'EOF'
[Default]
for=for (${cursor}) {\n}
if=if (${cursor}) {\n}
elif=else if (${cursor}) {\n}
else=else {\n}
while=while (${cursor}) {\n}
switch=switch (${cursor}) {\n}
case=case ${cursor}:\nbreak;
EOF

mkdir -p "$APPDIR/config/templates"

cat > "$APPDIR/config/templates/filetypes.c" << 'EOF'
#include <stdio.h>

int main(int argc, char *argv[]) {
    ${cursor}
    return 0;
}
EOF

cat > "$APPDIR/config/templates/filetypes.python" << 'EOF'
#!/usr/bin/env python3

def main():
    ${cursor}

if __name__ == "__main__":
    main()
EOF

cat > "$APPDIR/config/templates/filetypes.html" << 'EOF'
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

echo "=== Downloading AppImageTool ==="
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

echo "=== Building AppImage ==="
./appimagetool-x86_64.AppImage "$APPDIR"

echo "======================================="
echo " AppImage build complete!"
echo "======================================="
