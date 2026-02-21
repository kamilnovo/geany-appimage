#!/bin/bash
set -e

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
