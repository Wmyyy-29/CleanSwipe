# Contributing to CleanSwipe

[中文说明](#中文说明)

Thank you for helping improve CleanSwipe. Bug reports, feature ideas, documentation fixes, and code contributions are welcome.

## Before you start

- Search existing issues before opening a new one.
- Never attach personal photos, photo metadata, signing certificates, provisioning profiles, Apple IDs, or device identifiers.
- For security or privacy vulnerabilities, use GitHub's private security advisory feature instead of a public issue.
- Changes to photo authorization or deletion behavior must preserve the safety rules documented in [Architecture](docs/ARCHITECTURE.md).

## Development setup

1. Fork and clone the repository.
2. Open `CleanSwipeDemo.xcodeproj` in Xcode.
3. Select your own development team and use a unique bundle identifier if you want to run on a physical device.
4. Test with simulator images or disposable photos first.
5. Keep demo mode functional so reviewers can evaluate the app without granting photo access.

## Pull requests

- Keep each pull request focused on one change.
- Explain the user-visible behavior and any privacy impact.
- Include screenshots for interface changes, using only synthetic or non-personal content.
- Confirm that the project builds without third-party dependencies.
- Do not commit `xcuserdata`, build output, signing material, or secrets.

## Code style

- Follow existing Swift and SwiftUI conventions.
- Prefer small views and services with clear responsibilities.
- Keep PhotoKit mutations inside `PhotoLibraryService`.
- Add comments only where behavior or safety constraints are not obvious from the code.

## 中文说明

欢迎通过 Issue、文档修改或 Pull Request 参与 CleanSwipe。

- 提交前请先搜索已有 Issue。
- 不要上传私人照片、照片元数据、Apple ID、设备标识、签名证书或描述文件。
- 安全或隐私漏洞请使用 GitHub 私密安全报告，不要公开披露。
- 涉及相册授权和删除流程的修改，必须遵守 [架构说明](docs/ARCHITECTURE.md) 中的安全约束。
- 真机运行时请使用自己的开发团队和唯一 Bundle Identifier。
- UI 改动请附截图，但只能使用模拟或非个人内容。
- 提交前确认 Demo 模式可用、工程可以编译，并且没有加入第三方依赖或敏感文件。

