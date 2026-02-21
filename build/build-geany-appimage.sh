#!/bin/bash
set -e

############################################
# Always run from repository root
############################################

cd "$(dirname "$0")/.."
echo "Running from repo root: $PWD"

APPDIR="$PWD/AppDir"
mkdir -p "$APPDIR"

############################################
# Install build dependencies
############################################

sudo apt-get update
sudo apt-get install -y meson ninja-build pkg-config build-essential \
    libgtk-3-dev libglib2.0-dev libvte-2.91-dev

############################################
# Download Geany source if not present
############################################

if [ ! -d geany-2.0 ]; then
    echo "Downloading Geany 2.0..."
    wget https://download.geany.org/geany-2.0.tar.bz2
    tar xf geany-2.0.tar.bz2
fi

############################################
# Detect Geany directory (strict regex)
############################################

GEANY_DIR=$(find "$PWD" -maxdepth 1 -type d -regex ".*/geany-[0-9]+\.[0-9]+.*" | head -n 1)

echo "Detected Geany directory: $GEANY_DIR"

if [ ! -d "$GEANY_DIR" ]; then
    echo "ERROR: Geany directory not found!"
    exit 1
fi

############################################
# Build Geany
############################################

echo "=== Building Geany ==="
cd "$GEANY_DIR"

meson setup build --prefix=/usr
meson compile -C build
meson install -C build --destdir "$APPDIR"

############################################
# Back to repo root
############################################

cd "$PWD/.."

############################################
# Prepare environment for plugins
############################################

export PKG_CONFIG_PATH="$APPDIR/usr/lib/pkgconfig"
export CPPFLAGS="-I$APPDIR/usr/include/geany"
export CFLAGS="$CPPFLAGS"
export LDFLAGS="-L$APPDIR/usr/lib"

############################################
# Build Geany Plugins (whitelist)
############################################

PLUGIN_DIR=$(find "$PWD" -maxdepth 1 -type d -regex ".*/geany-plugins-[0-9]+\.[0-9]+.*" | head -n 1)
echo "Detected plugin directory: $PLUGIN_DIR"

cd "$PLUGIN_DIR"

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

############################################
# Build AppImage
############################################

cd "$PWD/.."

cp geany.desktop "$APPDIR"
cp geany.png "$APPDIR"

appimagetool "$APPDIR" geany.AppImage
