#!/bin/bash
set -e

############################################
# Configuration
############################################
VERSION="44.0"
REPO_URL="https://gitlab.gnome.org/GNOME/gnome-sudoku.git"
PROJECT_DIR="gnome-sudoku-$VERSION"
APPDIR="AppDir"

# Always run from script directory parent (gnome-sudoku)
cd "$(dirname "$0")/.."
REPO_ROOT="$PWD"
echo "Repo root: $REPO_ROOT"
export PATH="$REPO_ROOT/bin:$PATH"

# Clean up
rm -rf "$APPDIR" "$PROJECT_DIR"
mkdir -p "$APPDIR"

############################################
# 1. Download Source
############################################
if [ ! -d "$PROJECT_DIR" ]; then
    echo "=== Fetching gnome-sudoku $VERSION ==-"
    git clone --depth 1 --branch "$VERSION" "$REPO_URL" "$PROJECT_DIR"
fi

############################################
# 2. Setup Build Tools
############################################
if ! command -v meson &> /dev/null; then
    echo "=== Setting up Build Tools (Meson/Ninja) ==-"
    python3 -m venv venv_build
    source venv_build/bin/activate
    pip install meson ninja
else
    echo "Meson found in system."
fi

# Apply local patches to bypass missing GNU msgfmt if needed
echo "=== Patching build files for local compatibility ==-"
cd "$PROJECT_DIR"
if [ ! -f /usr/bin/msgfmt ]; then
    python3 /home/mbarina/dev/geany-appimage/patch_meson.py data/meson.build
    sed -i 's/i18n\.merge_file/find_program('true'), #/g' data/meson.build
    sed -i "/subdir('po')/d" meson.build
    sed -i "/subdir('help')/d" meson.build
fi

############################################
# 3. Build & Install to AppDir
############################################
echo "=== Building gnome-sudoku ==-"
meson setup build --prefix=/usr -Dbuildtype=release
meson compile -C build
DESTDIR="$REPO_ROOT/$APPDIR" meson install -C build

# Create a basic desktop file if missing (due to our translation patches)
if [ ! -f "$REPO_ROOT/$APPDIR/usr/share/applications/org.gnome.Sudoku.desktop" ]; then
    mkdir -p "$REPO_ROOT/$APPDIR/usr/share/applications"
    cat << EOF_D > "$REPO_ROOT/$APPDIR/usr/share/applications/org.gnome.Sudoku.desktop"
[Desktop Entry]
Name=Sudoku
Exec=gnome-sudoku
Icon=org.gnome.Sudoku
Terminal=false
Type=Application
Categories=GNOME;GTK;Game;StrategyGame;
EOF_D
fi
cd "$REPO_ROOT"

############################################
# 4. Packaging with linuxdeploy
############################################
echo "=== Packaging AppImage ==-"

TOOLS=(
    "linuxdeploy-x86_64.AppImage"
    "appimagetool-x86_64.AppImage"
)

for tool in "${TOOLS[@]}"; do
    if [ ! -f "$tool" ]; then
        echo "Downloading $tool..."
        case $tool in
            linuxdeploy-x86_64.AppImage)
                wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage -O "$tool"
                ;;
            appimagetool-x86_64.AppImage)
                wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O "$tool"
                ;;
        esac
        chmod +x "$tool"
    fi
done

export VERSION
./linuxdeploy-x86_64.AppImage --appdir "$APPDIR" \
    -e "$APPDIR/usr/bin/gnome-sudoku" \
    -d "$APPDIR/usr/share/applications/org.gnome.Sudoku.desktop" \
    -i "$APPDIR/usr/share/icons/hicolor/scalable/apps/org.gnome.Sudoku.svg" \
    --output appimage

echo "Done! gnome-sudoku AppImage built."
