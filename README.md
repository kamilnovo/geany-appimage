# Geany Portable Enhanced (AppImage)

This project provides a fully portable, improved version of **Geany** packaged as an **AppImage**.  
It includes a curated set of plugins, a modern dark theme, improved defaults, and a complete portable configuration that travels with the AppImage.

The goal is simple:  
**A polished, ready‑to‑use Geany environment that works anywhere — no installation required.**

---

## ✨ Features

### ✔ Fully Portable
All configuration files are stored inside:

Geany.AppDir/config/
Code


The AppImage can be run from USB drives, external disks, cloud folders, or any Linux system without leaving traces behind.

---

## 🎨 Preconfigured Environment

### Theme & UI
- Dark theme **Darcula**
- JetBrains Mono (if available), otherwise system fallback
- Sidebar on the left
- Clean, minimal toolbar layout
- Minimap enabled
- Modern editor ergonomics

### Editor Behavior
- Spaces instead of tabs
- Smart auto‑indent
- Highlight current line
- Brace matching
- Line numbers enabled
- UTF‑8 + Unix LF defaults

---

## 🔌 Included & Enabled Plugins

The AppImage comes with a curated set of plugins enabled by default:

| Plugin | Purpose |
|--------|---------|
| **TreeBrowser** | File explorer sidebar |
| **ColorPreview** | Inline color previews in code |
| **ExtraSel** | Advanced selection tools |
| **LineOperations** | Line manipulation utilities |
| **MultiTerm** | Embedded terminal |
| **Markdown** | Markdown support |

These plugins are compiled directly into the AppImage and activated automatically.

---

## 🧩 Additional Enhancements

### Snippets
Useful programming snippets for C, Python, HTML, and more.

### Templates
Predefined file templates for:
- C
- Python
- HTML

### Syntax Highlighting Improvements
Custom `filedefs` for:
- CSS (ColorPreview‑friendly)
- C (TODO highlighting)
- Python (f‑string highlighting)

### Toolbar Layout
A clean, professional toolbar defined in `ui_toolbar.xml`.

---

## 📦 Download

You can always find the latest version here:

👉 **Releases:** https://github.com/USERNAME/geany-appimage/releases

(Replace `USERNAME` with your GitHub username.)

---

## 🛠 Building from Source

```bash
git clone https://github.com/USERNAME/geany-appimage
cd geany-appimage
bash build/build-geany-appimage.sh

The resulting AppImage will appear in the project root.
🤖 Automated Builds & Releases

This project uses GitHub Actions to:

    Build the AppImage on every push to main

    Automatically create a GitHub Release when a tag is pushed

    Upload the AppImage and its .zsync file

    Embed AppImage update metadata

🔄 Auto‑Update Support

The AppImage includes update metadata, so it can be updated using:
bash

AppImageUpdate Geany*.AppImage

Delta updates are supported via .zsync files.
📄 License

This project is open‑source and follows the licensing terms of Geany and Geany‑Plugins.
