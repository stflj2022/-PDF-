#!/bin/bash
# PDF 重排工具 - 构建脚本

set -e

echo "========================================="
echo "  PDF 重排工具 - 打包脚本"
echo "========================================="
echo ""

# 检查 PyInstaller
if ! command -v pyinstaller &> /dev/null; then
    echo "❌ 未安装 PyInstaller"
    echo "正在安装..."
    pip3 install pyinstaller
fi

# 清理旧的构建文件
echo "🧹 清理旧的构建文件..."
rm -rf build/ dist/

# 开始打包
echo "🔨 开始打包..."
pyinstaller build.spec

# 检查是否成功
if [ -f "dist/pdf-retypeset" ]; then
    echo ""
    echo "✅ 打包成功！"
    echo ""
    echo "📦 可执行文件位置: dist/pdf-retypeset"
    echo ""
    echo "📋 使用方法:"
    echo "  GUI模式: ./dist/pdf-retypeset --gui"
    echo "  命令行:  ./dist/pdf-retypeset input.pdf output.pdf"
    echo ""
    
    # 显示文件大小
    SIZE=$(du -h dist/pdf-retypeset | cut -f1)
    echo "📊 文件大小: $SIZE"
    
    # 测试运行
    echo ""
    echo "🧪 测试运行..."
    ./dist/pdf-retypeset --help | head -5
    
    echo ""
    echo "✅ 可以将 dist/pdf-retypeset 复制到其他 Linux 电脑使用"
else
    echo ""
    echo "❌ 打包失败，请检查错误信息"
    exit 1
fi
