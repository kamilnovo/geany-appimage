markdown

# How the Geany AppImage Build Works

This document explains the internal structure of the project, how the build process works, and how you can extend or customize the AppImage.

---

## 📦 AppImage Structure

The build script creates the following structure:

Geany.AppDir/
├── usr/
│    ├── bin/geany
│    ├── lib/
│    ├── share/
│    └── plugins/
├── AppRun
└── geany.desktop
Code


Everything inside `AppDir` becomes part of the final AppImage.

The AppImage contains:

- Geany 2.0 (compiled from source)
- geany-plugins 2.0 (compiled from source)
- Color Preview plugin (with enlarged color squares)
- Icons, desktop file, and all required runtime libraries

---

## 🔧 Build Process Overview

The build script performs these steps:

1. Install build dependencies  
2. Download Geany source  
3. Download geany-plugins source  
4. Create AppDir  
5. Compile Geany  
6. Apply patches  
7. Compile plugins  
8. Install everything into AppDir  
9. Download `appimagetool`  
10. Build the final AppImage  

The result is a fully self-contained binary.

---

## 🎨 Color Preview Patch

The patch is located at:

build/patches/colorpreview-bigger-icons.patch
Code


It modifies the plugin to use larger color preview squares:

- Default: 8×8 px  
- Patched: 16×16 px  

You can adjust the size by editing the patch.

---

## 🧩 Adding or Removing Plugins

Plugins are enabled in the build script via:

./configure --enable-<plugin>
Code


To disable a plugin, remove its flag.

To enable all plugins:

./configure --enable-all-plugins
Code


⚠️ Some plugins require additional libraries.

---

## 🎨 Adding a Custom GTK Theme

You can bundle a GTK theme inside the AppImage:

1. Create directory:

Geany.AppDir/usr/share/themes/
Code


2. Copy your theme folder inside  
3. Set environment variable in `AppRun`:

export GTK_THEME=YourThemeName
Code


---

## 📁 Portable Configuration

To make Geany portable:

1. Create directory:

Geany.AppDir/config/
Code


2. Add to `AppRun`:

export GEANY_CONFIG_DIR="$APPDIR/config"
Code


This forces Geany to store settings inside the AppImage directory.

---

## 🧪 Testing the AppImage

Extract the AppImage for inspection:

./Geany-2.0-x86_64.AppImage --appimage-extract
Code


This creates a directory:

squashfs-root/
Code


---

## 🛠 Troubleshooting

### Build fails on missing dependencies  
Install them manually or extend the dependency list in the script.

### Patch fails  
The script continues even if the patch does not apply.  
Check plugin version compatibility.

### AppImage does not launch  
Run:

./Geany-2.0-x86_64.AppImage --appimage-debug
Code


---

## 🤝 Contributing

Feel free to submit pull requests with:

- new patches  
- new plugins  
- improvements to the build script  
- CI automation (GitHub Actions)  
