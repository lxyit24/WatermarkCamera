# WatermarkCamera

📷 Flutter 相机应用 - 支持水印功能

## 功能特点

- 📸 拍照功能
- 🎨 添加水印（文字水印）
- ⏰ 显示时间水印
- 📍 显示位置水印（待实现）
- 🌐 中文界面

## 技术栈

- **框架**：Flutter
- **语言**：Dart
- **状态管理**：Provider
- **相机**：camera 插件

## 项目结构

```
lib/
└── main.dart          # 主程序入口

android/
├── app/
│   ├── build.gradle.kts
│   └── src/main/
│       ├── AndroidManifest.xml  # 权限配置
│       ├── kotlin/              # Kotlin 源码
│       └── res/                 # 资源文件
├── build.gradle.kts
└── settings.gradle.kts
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Android SDK >= 21
- Android 设备（需要相机权限）

### 安装步骤

```bash
# 克隆仓库
git clone https://github.com/lxyit24/WatermarkCamera.git

# 进入项目目录
cd WatermarkCamera

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 权限说明

本应用需要以下权限：

| 权限 | 用途 |
|------|------|
| Camera | 拍照功能 |
| Storage | 保存照片 |

## 截图预览

（待添加）

## 开发相关

### 代码规范

项目使用 Flutter 官方推荐的分析规则，确保代码质量：

```bash
# 代码分析
flutter analyze

# 修复自动可修复的问题
flutter fix
```

### 构建发布

```bash
# 构建 Debug APK
flutter build apk --debug

# 构建 Release APK
flutter build apk --release
```

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目仅供学习参考使用。

---

⭐ 如果这个项目对你有帮助，请给一个 Star！
