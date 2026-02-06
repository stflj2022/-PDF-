#!/usr/bin/env python3
"""
PDF 重排工具 - 打包专用入口文件

这个文件用于 PyInstaller 打包，使用绝对导入避免相对导入问题。
"""

import argparse
import sys
from pathlib import Path

# 添加 src 目录到 Python 路径
src_path = Path(__file__).parent / "src"
sys.path.insert(0, str(src_path))

# 使用绝对导入
from config import Config, load_config
from pipeline import Pipeline


def main():
    """主入口"""
    parser = argparse.ArgumentParser(
        description="扫描版PDF字符级分割重排工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 使用GUI
  python main.py --gui

  # 命令行处理
  python main.py input.pdf output.pdf

  # 使用自定义配置
  python main.py input.pdf output.pdf --config config.yaml

  # 调整参数
  python main.py input.pdf output.pdf --scale 1.5 --dpi 300
        """,
    )

    parser.add_argument(
        "input",
        nargs="?",
        help="输入PDF或图像文件路径",
    )
    parser.add_argument(
        "output",
        nargs="?",
        help="输出文件路径",
    )
    parser.add_argument(
        "--gui",
        action="store_true",
        help="启动图形界面",
    )
    parser.add_argument(
        "--config",
        type=str,
        help="配置文件路径",
    )
    parser.add_argument(
        "--scale",
        type=float,
        default=None,
        help="字体缩放系数（默认：1.3）",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=None,
        help="渲染DPI（默认：200）",
    )
    parser.add_argument(
        "--lang",
        type=str,
        default=None,
        help="OCR语言（默认：chi_sim+eng）",
    )

    args = parser.parse_args()

    try:
        # 加载配置
        config = load_config(args.config)

        # 命令行参数覆盖配置
        if args.scale is not None:
            config.segmentation.scale = args.scale
        if args.dpi is not None:
            config.preprocessing.dpi = args.dpi
        if args.lang is not None:
            config.segmentation.lang = args.lang

        # GUI 模式
        if args.gui:
            from gui import run_gui
            run_gui(config)
            return

        # 命令行模式
        if not args.input or not args.output:
            parser.error("命令行模式需要指定输入和输出文件路径")

        # 执行处理
        input_path = Path(args.input)
        output_path = Path(args.output)

        if not input_path.exists():
            print(f"错误: 输入文件不存在: {input_path}")
            sys.exit(1)

        print(f"输入文件: {input_path}")
        print(f"输出文件: {output_path}")
        print(f"字体缩放: {config.segmentation.scale}")
        print(f"渲染DPI: {config.preprocessing.dpi}")

        pipeline = Pipeline(config)
        pipeline.process(input_path, output_path)

        print(f"\n✓ 处理完成！")
        print(f"  输入: {input_path}")
        print(f"  输出: {output_path}")

    except KeyboardInterrupt:
        print("\n\n用户取消")
        sys.exit(0)
    except Exception as e:
        print(f"\n错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
