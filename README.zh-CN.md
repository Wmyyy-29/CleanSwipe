<div align="center">
  <img src="CleanSwipeDemo/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="112" alt="CleanSwipe 应用图标">
  <h1>CleanSwipe</h1>
  <p>一张一张整理相册：保留、待删除，或稍后决定。</p>
  <p>
    <a href="README.md">English</a> ·
    <a href="PRIVACY.md">隐私声明</a> ·
    <a href="CONTRIBUTING.md">参与贡献</a>
  </p>
  <p>
    <img alt="iOS 17+" src="https://img.shields.io/badge/iOS-17.0%2B-000000?logo=apple">
    <img alt="Swift" src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white">
    <img alt="SwiftUI" src="https://img.shields.io/badge/UI-SwiftUI-0D96F6">
    <img alt="MIT License" src="https://img.shields.io/badge/License-MIT-2ea44f">
  </p>
</div>

## 界面预览

<p align="center">
  <img src="docs/images/home.png" width="23%" alt="CleanSwipe 首页">
  <img src="docs/images/swipe-delete.png" width="23%" alt="左划加入待删除">
  <img src="docs/images/review.png" width="23%" alt="删除前复查">
  <img src="docs/images/summary.png" width="23%" alt="本轮汇总">
</p>

## 为什么做 CleanSwipe？

面对几千张照片，缩略图网格很容易让人失去耐心。CleanSwipe 把整理过程拆成短小、专注的回合：一次只看一个项目，只做一个决定，并在真正删除前统一复查。

- **右划**：保留。
- **左划**：加入本轮待删除清单。
- **上划**：稍后决定。
- 回合中可随时**撤销上一步**。
- 提交给系统前可**逐项复查**。

## 功能

- 原生 SwiftUI 卡片交互、旋转动画和决策标签
- 真实 PhotoKit 相册访问，以及无需权限的安全演示模式
- 今天、本月、截图、长视频、随机和全部照片任务
- 可独立开关的声音与触感反馈
- 全屏预览、双击放大和双指缩放
- 每轮 50 个项目，包含进度、撤销、汇总和预计释放空间
- 删除前缩略图网格，可随时调整最终删除集合
- 待删除项目包含“收藏”照片时额外提醒
- 本地记录“已整理”项目，并可在设置中重置
- 无账号、无分析、无广告、无服务器、无照片上传

## 安全机制

CleanSwipe 刻意把“滑动决定”和“真正删除”分开：

1. 左划只把项目加入当前回合的待删除清单。
2. 用户在网格中复查全部待删除项目。
3. 用户确认最终集合。
4. App 通过 PhotoKit 向系统提交删除请求。
5. iOS 将项目移入系统“最近删除”，通常可在 30 天内恢复。

如果开启了 iCloud 照片，删除可能同步到使用相同 Apple Account 的其他设备。请先用不重要的测试照片验证流程。

## 环境要求

- 安装 Xcode 15 或更新版本的 macOS
- iOS 17.0 或更新版本
- 个人真机测试可使用免费 Apple Account；TestFlight/App Store 分发需要 Apple Developer Program

## 开始运行

```bash
git clone https://github.com/Wmyyy-29/CleanSwipe.git
cd CleanSwipe
open CleanSwipeDemo.xcodeproj
```

然后在 Xcode 中：

1. 选择 `CleanSwipeDemo` Target。
2. 打开 **Signing & Capabilities**。
3. 选择你自己的 Team。
4. 将 `com.personal.CleanSwipeDemo` 改成唯一的 Bundle Identifier。
5. 选择 iPhone 模拟器或已连接的 iPhone，按 `⌘R` 运行。
6. 建议先选择“演示模式”，或为真实相册测试授予有限/完全照片权限。

项目不依赖任何第三方库。

## 仓库结构

```text
CleanSwipe/
├── CleanSwipeDemo.xcodeproj
├── CleanSwipeDemo/
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   ├── Views/
│   ├── Assets.xcassets/
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy
├── docs/
│   ├── ARCHITECTURE.md
│   └── images/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
├── .gitignore
├── CONTRIBUTING.md
├── PRIVACY.md
├── SECURITY.md
├── README.md
└── LICENSE
```

组件职责和数据流请查看 [架构说明](docs/ARCHITECTURE.md)。

## 当前限制

- 释放空间是估算值；PhotoKit 没有通过简单公开属性提供每个资源的精确文件大小。
- “大视频”目前按时长排序，并非按精确编码文件大小排序。
- 尚未实现相似照片聚类、模糊检测和最佳照片推荐。
- 当前 App 界面为简体中文，英文界面本地化在计划中。
- 这是早期开源 Demo，不能替代可靠的照片备份。

## Roadmap

- [ ] 基于设备端分析的相似照片分组
- [ ] 模糊与闭眼检测
- [ ] 英文界面本地化
- [ ] 无障碍和 Dynamic Type 检查
- [ ] 单元测试和 UI 测试
- [ ] 不依赖分析追踪的更多整理统计

## 隐私

照片和元数据只在设备端处理。CleanSwipe 没有开发者后端、分析、广告或照片上传代码；为了显示仅存于 iCloud 的项目，PhotoKit 可能从苹果服务下载设备端副本。详情见 [隐私声明](PRIVACY.md)。

## 参与贡献

欢迎提交 Issue 和 Pull Request。涉及相册权限或删除行为的修改，请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## License

CleanSwipe 使用 [MIT License](LICENSE) 开源。

## 免责声明

CleanSwipe 是独立开源项目，与 Apple Inc. 或 Tinder LLC 没有关联，也未获得其赞助或背书。Apple、iPhone、iCloud、PhotoKit 等名称及标识归各自权利人所有。
