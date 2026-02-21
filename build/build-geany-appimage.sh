#!/bin/bash
set -e

############################################
# Always run from repository root
############################################

cd "$(dirname "$0")/.."
REPO_ROOT="$PWD"
echo "Running from repo root: $REPO_ROOT"

APPDIR="$REPO_ROOT/AppDir"
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

if [ ! -d "$REPO_ROOT/geany-2.0" ]; then
    echo "Downloading Geany 2.0..."
    wget https://download.geany.org/geany-2.0.tar.bz2
    tar xf geany-2.0.tar.bz2
fi

############################################
# Detect Geany directory (strict regex)
############################################

GEANY_DIR=$(find "$REPO_ROOT" -maxdepth 1 -type d -regex ".*/geany-[0-9]+\.[0-9]+.*" | head -n 1)
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

./configure --prefix=/usr
make -j$(nproc)
make install DESTDIR="$APPDIR"

# Install internal headers needed by plugins
echo "Installing internal Geany headers..."
cp -r src/* "$APPDIR/usr/include/geany/"


############################################
# Back to repo root
############################################

cd "$REPO_ROOT"

############################################
# Prepare environment for plugins
############################################

export PKG_CONFIG_PATH="$APPDIR/usr/lib/pkgconfig"
export CPPFLAGS="-I$APPDIR/usr/include/geany"
export CFLAGS="$CPPFLAGS"
export LDFLAGS="-L$APPDIR/usr/lib"


############################################
# Download Geany Plugins if not present
############################################

if ! ls "$REPO_ROOT"/geany-plugins-* >/dev/null 2>&1; then
    echo "Downloading Geany Plugins 2.0..."
    wget https://plugins.geany.org/geany-plugins/geany-plugins-2.0.tar.bz2
    tar xf geany-plugins-2.0.tar.bz2
fi


############################################
# Detect plugin directory
############################################

PLUGIN_DIR=$(find "$REPO_ROOT" -maxdepth 1 -type d -regex ".*/geany-plugins-[0-9]+\.[0-9]+.*" | head -n 1)
echo "Detected plugin directory: $PLUGIN_DIR"

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "ERROR: Plugin directory not found!"
    exit 1
fi

cd "$PLUGIN_DIR"


############################################
# Build plugins (whitelist)
############################################

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

cd "$REPO_ROOT"

cp geany.desktop "$APPDIR"
cp geany.png "$APPDIR"

appimagetool "$APPDIR" geany.AppImage
