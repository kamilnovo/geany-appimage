#!/bin/bash
set -e

# Always run from repository root
cd "$(dirname "$0")/.."

APPDIR="$PWD/AppDir"
mkdir -p "$APPDIR"

echo "Running from: $PWD"

############################################
# Download Geany
############################################

if [ ! -d geany-2.0 ]; then
    wget https://download.geany.org/geany-2.0.tar.bz2
    tar xf geany-2.0.tar.bz2
fi

############################################
# Detect Geany directory (absolute path)
############################################

GEANY_DIR=$(find "$PWD" -maxdepth 1 -type d -name "geany-*" | head -n 1)
echo "Detected Geany directory: $GEANY_DIR"

cd "$GEANY_DIR"

############################################
# Build Geany
############################################

echo "=== Building Geany ==="
cd geany-2.0

meson setup build --prefix=/usr
meson compile -C build
meson install -C build --destdir "$APPDIR"

cd ..

############################################
# 2) Prepare environment for plugins
############################################

export PKG_CONFIG_PATH="$APPDIR/usr/lib/pkgconfig"
export CPPFLAGS="-I$APPDIR/usr/include/geany"
export CFLAGS="$CPPFLAGS"
export LDFLAGS="-L$APPDIR/usr/lib"

echo "PKG_CONFIG_PATH = $PKG_CONFIG_PATH"
echo "CPPFLAGS = $CPPFLAGS"
echo "LDFLAGS = $LDFLAGS"

############################################
# 3) Build Geany Plugins (whitelist only)
############################################

echo "=== Building Geany Plugins ==="
cd geany-plugins-2.0

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
make install DESTDIR="$APPDIR"

cd ..

############################################
# 4) Bundle AppImage
############################################

echo "=== Creating AppImage ==="

cp geany.desktop "$APPDIR"
cp geany.png "$APPDIR"

appimagetool "$APPDIR" geany.AppImage
