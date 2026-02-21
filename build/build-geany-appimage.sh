#!/bin/bash
set -e

############################################
# Always run from repository root
############################################

cd "$(dirname "$0")/.."
REPO_ROOT="$PWD"
echo "Repo root: $REPO_ROOT"

APPDIR="$REPO_ROOT/AppDir"
mkdir -p "$APPDIR"

############################################
# Install build dependencies
############################################

sudo apt-get update
sudo apt-get install -y \
    build-essential \
    pkg-config \
    libgtk-3-dev \
    libglib2.0-dev \
    libvte-2.91-dev \
    libxml2-dev \
    libpcre2-dev \
    libtool \
    automake \
    autoconf

############################################
# Build Geany 1.38
############################################

echo "=== Building Geany 1.38 ==="
cd "$REPO_ROOT"

# Download Geany 1.38
if [ ! -f geany-1.38.tar.bz2 ]; then
    wget https://download.geany.org/geany-1.38.tar.bz2
fi

# Extract if missing
if [ ! -d geany-1.38 ]; then
    tar xf geany-1.38.tar.bz2
fi

GEANY_DIR=$(find "$REPO_ROOT" -maxdepth 1 -type d -name "geany-1.38*")
echo "Detected Geany directory: $GEANY_DIR"

cd "$GEANY_DIR"

./configure --prefix=/usr
make -j$(nproc)
make install DESTDIR="$APPDIR"

############################################
# Install internal Geany headers (needed by plugins)
############################################

echo "Installing internal Geany headers..."

# Copy all headers from src/
cp src/*.h "$APPDIR/usr/include/geany/"

# Copy tm subsystem (exists in 1.38)
mkdir -p "$APPDIR/usr/include/geany/tm"
cp src/tm/*.h "$APPDIR/usr/include/geany/tm/"

############################################
# Build Geany Plugins 1.38
############################################

cd "$REPO_ROOT"

# Download plugins
if [ ! -f geany-plugins-1.38.tar.bz2 ]; then
    wget https://plugins.geany.org/geany-plugins/geany-plugins-1.38.tar.bz2
fi

# Extract if missing
if [ ! -d geany-plugins-1.38 ]; then
    tar xf geany-plugins-1.38.tar.bz2
fi

PLUGIN_DIR=$(find "$REPO_ROOT" -maxdepth 1 -type d -name "geany-plugins-1.38*")
echo "Detected plugin directory: $PLUGIN_DIR"

cd "$PLUGIN_DIR"

./configure --prefix=/usr \
    --enable-treebrowser \
    --enable-lineoperations \
    --enable-geanymacro \
    --enable-geanyminiscript \
    --enable-geanynumberedbookmarks \
    --enable-projectorganizer \
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
