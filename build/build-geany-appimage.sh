############################################
# Build Geany 1.38
############################################

echo "=== Building Geany 1.38 ==="
cd "$REPO_ROOT"

# Download Geany 1.38
if [ ! -d geany-1.38 ]; then
    echo "Downloading Geany 1.38..."
    wget https://download.geany.org/geany-1.38.tar.bz2
    tar xf geany-1.38.tar.bz2
fi

# Detect Geany directory
GEANY_DIR=$(find "$REPO_ROOT" -maxdepth 1 -type d -regex ".*/geany-1\.38.*" | head -n 1)
echo "Detected Geany directory: $GEANY_DIR"

cd "$GEANY_DIR"

./configure --prefix=/usr
make -j$(nproc)
make install DESTDIR="$APPDIR"

############################################
# Install internal headers (Geany 1.38)
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
if [ ! -d geany-plugins-1.38 ]; then
    echo "Downloading Geany Plugins 1.38..."
    wget https://plugins.geany.org/geany-plugins/geany-plugins-1.38.tar.bz2
    tar xf geany-plugins-1.38.tar.bz2
fi

PLUGIN_DIR=$(find "$REPO_ROOT" -maxdepth 1 -type d -regex ".*/geany-plugins-1\.38.*" | head -n 1)
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
