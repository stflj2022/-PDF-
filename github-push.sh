#!/bin/bash
# GitHub 仓库初始化和推送脚本

set -e

echo "========================================="
echo "  PDF 重排工具 - GitHub 推送脚本"
echo "========================================="
echo ""

# 检查是否已安装 git
if ! command -v git &> /dev/null; then
    echo "❌ 未安装 Git"
    echo "请先安装: sudo apt install git"
    exit 1
fi

# 进入项目目录
cd "$(dirname "$0")"

# 检查是否已经是 git 仓库
if [ ! -d ".git" ]; then
    echo "🔧 初始化 Git 仓库..."
    git init

    # 添加远程仓库（用户需要替换成自己的仓库地址）
    echo ""
    echo "⚠️  请输入你的 GitHub 仓库地址:"
    echo "   格式: https://github.com/username/repo.git"
    echo ""
    read -p "GitHub 仓库地址: " REPO_URL

    if [ -n "$REPO_URL" ]; then
        git remote add origin "$REPO_URL"
    else
        echo "⚠️  未配置远程仓库，稍后可手动添加"
    fi
fi

# 创建 .gitignore（如果不存在）
if [ ! -f ".gitignore" ]; then
    echo "📝 创建 .gitignore..."
    cat > .gitignore << 'EOF'
# PyInstaller
dist/
build/
*.spec

# Python
__pycache__/
*.pyc
*.pyo
*.pyd

# IDE
.vscode/
.idea/

# 系统文件
.DS_Store
Thumbs.db

# 备份
*.backup
*.bak
EOF
fi

# 添加所有文件
echo "📦 添加文件到 Git..."
git add .

# 检查是否有变更
if git diff --cached --quiet; then
    echo ""
    echo "ℹ️  没有需要提交的更改"
    exit 0
fi

# 提交
echo ""
git commit -m "Initial commit: PDF 重排工具 v1.0

功能特点:
- 扫描版PDF字块放大重排
- 竖版自动转横版
- GUI + 命令行模式
- OCR边界框检测

完成度: 97%
"

# 推送到 GitHub
echo ""
echo "🚀 推送到 GitHub..."
if git remote | grep -q "origin"; then
    # 检查主分支名称
    MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

    # 创建并推送主分支
    if ! git show-ref --verify --quiet refs/heads/$MAIN_BRANCH; then
        git branch -M $MAIN_BRANCH
    fi

    git push -u origin $MAIN_BRANCH
else
    echo "⚠️  未配置远程仓库"
    echo ""
    echo "请手动添加远程仓库:"
    echo "  git remote add origin https://github.com/yourusername/pdf-retypeset.git"
    echo "  git push -u origin main"
fi

echo ""
echo "✅ 完成！"
