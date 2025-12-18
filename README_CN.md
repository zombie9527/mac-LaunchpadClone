# LaunchpadClone (启动台替代方案)

一个基于 SwiftUI 构建的高性能、原生 macOS 启动台替代应用。

## 功能特性

- **原生性能**：使用 SwiftUI 和 AppKit 开发，确保操作流畅、无卡顿。
- **快速扫描**：自动扫描 `/Applications`、`/System/Applications` 以及 `~/Applications` 目录。
- **异步图标加载**：图标在后台加载，确保 UI 界面始终响应及时。
- **内存缓存**：使用 `NSCache` 实现图标秒开，避免重复加载。
- **实时搜索**：支持按名称快速过滤应用。
- **现代 UI 设计**：原生毛玻璃背景效果及优雅的悬停动画。

## 系统要求

- macOS 14.0 或更高版本
- Swift 5.9+

## 如何运行

1. 克隆仓库或进入项目文件夹。
2. 打开终端并运行：
   ```bash
   cd LaunchpadClone
   swift run LaunchpadClone
   ```

## 如何打包为 .app

若要创建一个可以移动到“应用程序”文件夹的独立 `.app` 包：

1. 进入 `LaunchpadClone` 目录。
2. 运行打包脚本：
   ```bash
   ./package.sh
   ```
3. 当前目录下将生成 `LaunchpadClone.app`。


## 项目结构

- `Sources/LaunchpadClone/`：包含 Swift 源代码。
- `Package.swift`：Swift Package Manager 配置文件。

## 开源协议

MIT
