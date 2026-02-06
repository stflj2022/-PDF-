#!/bin/bash
# PDF 重排工具 - AppImage 打包脚本

set -e

echo "========================================="
echo "  PDF 重排工具 - AppImage 打包脚本"
echo "========================================="
echo ""

# 配置
APP_NAME="pdf-retypeset"
APP_VERSION="1.0.0"
ARCH="x86_64"

# 临时目录
BUILD_DIR="appimage-build"
APPDIR="$BUILD_DIR/$APP_NAME.AppDir"

# 清理旧文件
echo "🧹 清理旧的构建文件..."
rm -rf "$BUILD_DIR" "appimage-*.AppImage"

# 创建 AppDir 结构
echo "📁 创建 AppDir 结构..."
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# 复制 Python 脚本
echo "📦 复制项目文件..."
cp -r src "$APPDIR/usr/bin/"
cp config.yaml "$APPDIR/usr/bin/"
cp requirements.txt "$APPDIR/usr/bin/"

# 创建启动脚本
echo "🔧 创建启动脚本..."
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
# AppImage 启动脚本

# 获取 AppImage 所在目录
SELF=$(readlink -f "$0")
HERE=${SELF%/*}

# 设置 Python 路径
export PATH="$HERE/usr/bin:$PATH"
export PYTHONPATH="$HERE/usr/bin:$PYTHONPATH"

# 检查参数
if [ "$1" = "--gui" ]; then
    cd "$HERE/usr/bin"
    python3 -m src.main --gui
elif [ -f "$1" ]; then
    cd "$HERE/usr/bin"
    python3 -m src.main "$@"
else
    cd "$HERE/usr/bin"
    python3 -m src.main --help
fi
EOF

chmod +x "$APPDIR/AppRun"

# 创建桌面文件
echo "📝 创建桌面文件..."
cat > "$APPDIR/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=PDF Retypeset Tool
Comment=扫描版PDF字块放大重排工具
Exec=pdf-retypeset
Icon=pdf-retypeset
Terminal=true
Type=Application
Categories=Utility;Office;
EOF

# 创建简单的图标（使用文本）
echo "🎨 创建图标..."
convert -size 256x256 xc:white \
  -fill black \
  -pointsize 72 \
  -gravity center \
  -annotate +0+0 "PDF" \
  "$APPDIR/usr/share/icons/hicolor/256x256/apps/pdf-retypeset.png" 2>/dev/null || \
echo "⚠️  未安装 ImageMagick，跳过图标生成"

# 下载 linuxdeploy
echo "📥 下载 linuxdeploy..."
LINUXDEPLOY="$BUILD_DIR/linuxdeploy-x86_64.AppImage"
if [ ! -f "$LINUXDEPLOY" ]; then
    wget -q \
      "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage" \
      -O "$LINUXDEPLOY"
    chmod +x "$LINUXDEPLOY"
fi

# 下载 linuxdeploy-python-plugin
echo "📥 下载 linuxdeploy-python-plugin..."
PYTHON_PLUGIN="$BUILD_DIR/linuxdeploy-plugin-python-x86_64.AppImage"
if [ ! -f "$PYTHON_PLUGIN" ]; then
    wget -q \
      "https://github.com/linuxdeploy/linuxdeploy-plugin-python/releases/download/continuous/linuxdeploy-plugin-python-x86_64.AppImage" \
      -O "$PYTHON_PLUGIN"
    chmod +x "$PYTHON_PLUGIN"
fi

# 使用 linuxdeploy 构建 AppImage
echo "🔨 构建 AppImage..."
export QMAKE="$BUILD_DIR/linuxdeploy-x86_64.AppImage"
export PYTHON="$BUILD_DIR/linuxdeploy-plugin-python-x86_64.AppImage"

cd "$BUILD_DIR"
"$LINUXDEPLOY" \
  --appdir="$APPDIR" \
  --plugin python \
  --output appimage

# 移动生成的 AppImage
mv "$APP_NAME"*.AppImage ../ 2>/dev/null || true

# 清理
cd ..
echo ""
echo "✅ AppImage 构建完成！"

# 检查是否成功
for app in pdf-retypeset*.AppImage; do
    if [ -f "$app" ]; then
        echo ""
        echo "📦 可执行文件: $app"
        SIZE=$(du -h "$app" | cut -f1)
        echo "📊 文件大小: $SIZE"
        echo ""
        echo "🚀 使用方法:"
        echo "  chmod +x $app"
        echo "  ./$app --gui"
        echo ""
        echo "✅ 可以复制到任何 Linux 系统运行！"
        break
    fi
done
