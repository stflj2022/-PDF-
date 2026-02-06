#!/bin/bash
# PDF 重排工具 - 自包含启动脚本
# 自动检测并安装系统依赖

set -e

echo "========================================="
echo "  PDF 重排工具"
echo "========================================="
echo ""

# 检查系统依赖
check_dependencies() {
    MISSING=""

    if ! dpkg -l | grep -q poppler-utils; then
        MISSING="$MISSING poppler-utils"
    fi

    if ! dpkg -l | grep -q tesseract-ocr; then
        MISSING="$MISSING tesseract-ocr"
    fi

    if ! dpkg -l | grep -q tesseract-ocr-chi-sim; then
        MISSING="$MISSING tesseract-ocr-chi-sim"
    fi

    if [ -n "$MISSING" ]; then
        echo "⚠️  缺少系统依赖: $MISSING"
        echo ""
        echo "正在安装..."
        sudo apt update
        sudo apt install -y $MISSING
        echo "✅ 依赖安装完成"
        echo ""
    else
        echo "✅ 系统依赖检查通过"
        echo ""
    fi
}

# 主程序
main() {
    # 检查依赖
    check_dependencies

    # 获取脚本所在目录
    DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # 运行程序
    if [ "$1" = "--gui" ]; then
        cd "$DIR"
        python3 -m src.main --gui
    elif [ -f "$1" ]; then
        cd "$DIR"
        python3 -m src.main "$@"
    else
        cd "$DIR"
        python3 -m src.main --help
    fi
}

# 运行主程序
main "$@"
