# CleanSwipe Privacy Statement / 隐私声明

Last updated / 最后更新：2026-07-31

## English

CleanSwipe is designed to organize a photo library without sending photos or personal data to a server.

### Data the app accesses

With explicit system permission, CleanSwipe may access photos and videos managed by Apple Photos, together with metadata required for the interface, such as creation date, media type, pixel dimensions, duration, Favorite status, and screenshot status.

The app requests read/write Photos access because it displays library assets and, only after user review and confirmation, asks PhotoKit to delete selected assets.

### Data stored on the device

CleanSwipe stores a small set of PhotoKit local asset identifiers in `UserDefaults` to avoid showing completed items repeatedly. It also stores the last selected launch mode. This information remains inside the app sandbox and can be reset from the app’s settings or removed by uninstalling the app.

CleanSwipe does not store copies of the user’s photos or videos.

When an asset is stored only in iCloud, CleanSwipe allows PhotoKit to request an on-device copy through Apple Photos so it can be displayed. That transfer is handled by Apple under the user's iCloud Photos settings. CleanSwipe has no developer-operated server and does not send the asset to the project maintainer or an advertising, analytics, or other third-party service.

### Deletion behavior

A swipe does not immediately delete an asset. Deletions are staged, reviewed, and confirmed before the app submits a PhotoKit deletion request. iOS controls the final operation and normally moves deleted assets to **Recently Deleted** for 30 days. When iCloud Photos is enabled, deletion may synchronize to other devices using the same Apple Account.

### Data collection and sharing

The current open-source version:

- does not create user accounts;
- does not contain analytics or advertising SDKs;
- does not upload photos, videos, metadata, or local identifiers;
- does not sell or share personal data;
- does not include a backend service.

Demo Mode uses synthetic cards and does not access the real photo library.

### Third-party contributions

Forks and modified builds are controlled by their respective maintainers. Review changes before installing an unofficial build. This statement applies to the source code in this repository at the revision in which it appears.

### Contact

For privacy questions or suspected privacy/security issues, open a GitHub issue. For sensitive reports, use GitHub’s private security advisory feature instead of posting personal information publicly.

---

## 简体中文

CleanSwipe 的设计目标是在不把照片或个人数据发送到服务器的情况下整理相册。

### App 访问的数据

获得明确的系统授权后，CleanSwipe 可以访问由苹果“照片”管理的照片和视频，以及界面所需的元数据，例如创建时间、媒体类型、像素尺寸、视频时长、收藏状态和截图状态。

App 需要照片读写权限，因为它需要显示相册项目，并且只在用户完成复查和确认后，通过 PhotoKit 请求删除选中的项目。

### 保存在设备上的数据

CleanSwipe 会在 `UserDefaults` 中保存少量 PhotoKit 本地资源标识符，用于避免重复展示已经整理完成的项目，同时保存上次选择的启动模式。这些信息只存在于 App 沙盒内，可在 App 设置中重置，也会在卸载 App 后删除。

CleanSwipe 不会保存用户照片或视频的副本。

如果某个项目的原始内容只存在于 iCloud，CleanSwipe 会允许 PhotoKit 通过苹果“照片”下载一份设备端副本，以便显示。该传输由苹果根据用户的 iCloud 照片设置处理。CleanSwipe 没有开发者运营的服务器，也不会把照片发送给项目维护者、广告平台、分析平台或其他第三方服务。

### 删除行为

滑动操作不会立即删除照片。项目会先进入待删除清单，经过复查和最终确认后，App 才会向 PhotoKit 提交删除请求。最终操作由 iOS 控制，删除的项目通常会进入系统“最近删除”并保留 30 天。如果开启了 iCloud 照片，删除可能同步到使用同一 Apple Account 的其他设备。

### 数据收集与共享

当前开源版本：

- 不创建用户账号；
- 不包含分析或广告 SDK；
- 不上传照片、视频、元数据或本地标识符；
- 不出售或共享个人数据；
- 不包含后端服务。

演示模式使用合成卡片，不访问真实相册。

### 第三方修改版本

Fork 或其他修改版本由相应维护者控制。安装非官方构建前，请自行检查代码变更。本声明仅适用于包含本文件的当前仓库源码版本。

### 联系方式

隐私问题可通过 GitHub Issue 联系。涉及敏感信息的安全报告，请使用 GitHub Private Security Advisory，不要在公开 Issue 中发布个人信息。
