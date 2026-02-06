"""
配置管理模块

处理配置文件的加载、验证和默认值设置。
"""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
import yaml


@dataclass
class BinarizationConfig:
    """二值化配置"""
    method: str = "adaptive"  # otsu | adaptive
    block_size: int = 11
    c: int = 2


@dataclass
class DenoiseConfig:
    """去噪配置"""
    enabled: bool = True
    kernel_size: int = 3


@dataclass
class DeskewConfig:
    """倾斜校正配置"""
    enabled: bool = False


@dataclass
class PreprocessingConfig:
    """预处理配置"""
    grayscale: bool = True
    binarization: BinarizationConfig = field(default_factory=BinarizationConfig)
    denoise: DenoiseConfig = field(default_factory=DenoiseConfig)
    deskew: DeskewConfig = field(default_factory=DeskewConfig)


@dataclass
class SegmentationConfig:
    """字符分割配置"""
    min_char_width: int = 10  # 最小字符宽度
    min_char_height: int = 15  # 最小字符高度
    min_area: int = 100  # 最小字符面积（备用）
    max_area: int = 50000  # 最大字符面积（备用）


@dataclass
class OutputLayoutConfig:
    """输出布局配置"""
    page_size: str = "A4"
    dpi: int = 300
    margin: int = 100
    char_spacing: int = 10
    line_spacing: int = 20
    scale_factor: float = 1.5
    background: str = "white"


@dataclass
class LayoutConfig:
    """布局配置"""
    direction: str = "vertical_to_horizontal"  # 竖转横
    reading_order: str = "right_to_left"  # 古籍从右到左
    output: OutputLayoutConfig = field(default_factory=OutputLayoutConfig)


@dataclass
class InputConfig:
    """输入配置"""
    type: str = "pdf"  # pdf | image
    dpi: int = 300


@dataclass
class OutputConfig:
    """输出配置"""
    format: str = "pdf"  # pdf | images
    quality: int = 95


@dataclass
class Config:
    """主配置类"""
    input: InputConfig = field(default_factory=InputConfig)
    preprocessing: PreprocessingConfig = field(default_factory=PreprocessingConfig)
    segmentation: SegmentationConfig = field(default_factory=SegmentationConfig)
    layout: LayoutConfig = field(default_factory=LayoutConfig)
    output: OutputConfig = field(default_factory=OutputConfig)

    @classmethod
    def from_yaml(cls, path: Path) -> "Config":
        """从YAML文件加载配置"""
        with open(path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return cls.from_dict(data)

    @classmethod
    def from_dict(cls, data: dict) -> "Config":
        """从字典创建配置"""
        config = cls()

        if "input" in data:
            config.input = InputConfig(**data["input"])

        if "preprocessing" in data:
            prep = data["preprocessing"]
            config.preprocessing = PreprocessingConfig(
                grayscale=prep.get("grayscale", True),
                binarization=BinarizationConfig(**prep.get("binarization", {})),
                denoise=DenoiseConfig(**prep.get("denoise", {})),
                deskew=DeskewConfig(**prep.get("deskew", {})),
            )

        if "segmentation" in data:
            config.segmentation = SegmentationConfig(**data["segmentation"])

        if "layout" in data:
            layout = data["layout"]
            output_layout = OutputLayoutConfig(**layout.get("output", {}))
            config.layout = LayoutConfig(
                direction=layout.get("direction", "vertical_to_horizontal"),
                reading_order=layout.get("reading_order", "right_to_left"),
                output=output_layout,
            )

        if "output" in data:
            config.output = OutputConfig(**data["output"])

        return config

    def to_dict(self) -> dict:
        """转换为字典"""
        return {
            "input": {
                "type": self.input.type,
                "dpi": self.input.dpi,
            },
            "preprocessing": {
                "grayscale": self.preprocessing.grayscale,
                "binarization": {
                    "method": self.preprocessing.binarization.method,
                    "block_size": self.preprocessing.binarization.block_size,
                    "c": self.preprocessing.binarization.c,
                },
                "denoise": {
                    "enabled": self.preprocessing.denoise.enabled,
                    "kernel_size": self.preprocessing.denoise.kernel_size,
                },
                "deskew": {
                    "enabled": self.preprocessing.deskew.enabled,
                },
            },
            "segmentation": {
                "min_area": self.segmentation.min_area,
                "max_area": self.segmentation.max_area,
                "merge_threshold": self.segmentation.merge_threshold,
            },
            "layout": {
                "direction": self.layout.direction,
                "reading_order": self.layout.reading_order,
                "output": {
                    "page_size": self.layout.output.page_size,
                    "dpi": self.layout.output.dpi,
                    "margin": self.layout.output.margin,
                    "char_spacing": self.layout.output.char_spacing,
                    "line_spacing": self.layout.output.line_spacing,
                    "scale_factor": self.layout.output.scale_factor,
                    "background": self.layout.output.background,
                },
            },
            "output": {
                "format": self.output.format,
                "quality": self.output.quality,
            },
        }


# 页面尺寸定义 (宽, 高) 单位: 像素 @ 300dpi
PAGE_SIZES = {
    "A4": (2480, 3508),
    "A5": (1748, 2480),
    "Letter": (2550, 3300),
    "B5": (2150, 3035),
}


def get_page_size(name: str, dpi: int = 300) -> tuple[int, int]:
    """获取页面尺寸（像素）"""
    if name not in PAGE_SIZES:
        raise ValueError(f"Unknown page size: {name}. Available: {list(PAGE_SIZES.keys())}")

    base_width, base_height = PAGE_SIZES[name]
    # 基准是300dpi，按比例调整
    scale = dpi / 300
    return int(base_width * scale), int(base_height * scale)


def load_config(config_path: Optional[Path] = None) -> Config:
    """加载配置，如果没有指定路径则使用默认配置"""
    if config_path and config_path.exists():
        return Config.from_yaml(config_path)
    return Config()
