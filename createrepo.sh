#!/bin/bash

echo "=== Creating project structure ==="

# Main directories
mkdir -p build/patches
mkdir -p Geany.AppDir/config/templates
mkdir -p Geany.AppDir/config/plugins
mkdir -p Geany.AppDir/config/filedefs
mkdir -p .github/workflows

echo "=== Creating .gitignore ==="
cat > .gitignore << 'EOF'
# Ignore build artifacts
geany-*/
geany-plugins-*/
*.AppImage
*.zsync
*.tar.gz
*.zip
*.bz2
*.AppDir
EOF

echo "=== Creating LICENSE (GPL-compatible) ==="
cat > LICENSE << 'EOF'
This project bundles Geany and Geany-Plugins, which are licensed under the GNU General Public License (GPL).
All modifications and build scripts in this repository follow the same license.
EOF

echo "=== Creating README.md ==="
cat > README.md << 'EOF'
# Geany Portable Enhanced (AppImage)

This project provides a fully portable, improved version of **Geany** packaged as an **AppImage**.
It includes a curated set of plugins, a modern dark theme, improved defaults, and a complete portable configuration.

The goal is simple:
**A polished, ready‑to‑use Geany environment that works anywhere — no installation required.**

## Features
- Fully portable configuration
- Darcula theme
- JetBrains Mono support
- TreeBrowser, ColorPreview, ExtraSel, LineOperations, MultiTerm, Markdown plugins
- Custom toolbar layout
- Improved syntax highlighting
- Snippets and templates included
- Auto‑update support via AppImageUpdate

## Download
Releases: https://github.com/USERNAME/geany-appimage/releases

## Build
bash build/build-geany-appimage.sh
EOF

echo "=== Creating CHANGELOG.md ==="
cat > CHANGELOG.md << 'EOF'
# Changelog

## [v2.0-enhanced1] – 2026-02-21

### Added
- Fully portable Geany AppImage build
- Preconfigured Darcula theme
- JetBrains Mono font support
- TreeBrowser, ColorPreview, ExtraSel, LineOperations, MultiTerm, Markdown plugins
- Custom toolbar layout
- Improved syntax highlighting
- Snippets and templates
- Minimap enabled
- Modern editor defaults
- GitHub Actions automated build
- Automatic GitHub Releases on tag
- AppImage update metadata + zsync delta updates
- English README
EOF

echo "=== Creating GitHub Actions workflow ==="
cat > .github/workflows/build-appimage.yml << 'EOF'
name: Build Geany AppImage

on:
  push:
    branches: [ "main" ]
    tags: [ "v*" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: sudo apt update && sudo apt install -y build-essential autoconf automake libtool pkg-config libgtk-3-dev libxml2-dev intltool wget git fuse libfuse2 libvte-2.91-dev libenchant-2-dev libaspell-dev zsync

      - name: Build AppImage
        run: bash build/build-geany-appimage.sh

      - name: Upload AppImage artifact
        uses: actions/upload-artifact@v4
        with:
          name: Geany-AppImage
          path: "*.AppImage"

  release:
    needs: build
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')

    steps:
      - name: Download AppImage artifact
        uses: actions/download-artifact@v4
        with:
          name: Geany-AppImage

      - name: Generate zsync file
        run: |
          for f in *.AppImage; do
            zsyncmake "$f" -o "$f.zsync"
          done

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            *.AppImage
            *.zsync
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

echo "=== Creating placeholder config files ==="

# geany.conf
cat > Geany.AppDir/config/geany.conf << 'EOF'
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

# TreeBrowser
cat > Geany.AppDir/config/plugins/treebrowser.conf << 'EOF'
[General]
show_hidden=false
follow_current=true
expand_root=true
show_bookmarks=false
EOF

# Snippets
cat > Geany.AppDir/config/snippets.conf << 'EOF'
[Default]
for=for (${cursor}) {\n}
if=if (${cursor}) {\n}
elif=else if (${cursor}) {\n}
else=else {\n}
while=while (${cursor}) {\n}
switch=switch (${cursor}) {\n}
case=case ${cursor}:\nbreak;
EOF

# Templates
cat > Geany.AppDir/config/templates/filetypes.c << 'EOF'
#include <stdio.h>

int main(int argc, char *argv[]) {
    ${cursor}
    return 0;
}
EOF

cat > Geany.AppDir/config/templates/filetypes.python << 'EOF'
#!/usr/bin/env python3

def main():
    ${cursor}

if __name__ == "__main__":
    main()
EOF

cat > Geany.AppDir/config/templates/filetypes.html << 'EOF'
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

echo "=== Project structure created successfully ==="
