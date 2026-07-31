# CleanSwipe Architecture / 架构说明

CleanSwipe is a small native SwiftUI application. It uses Apple's PhotoKit framework directly and has no third-party packages, developer-operated backend, analytics SDK, or direct network layer. PhotoKit may use Apple services to retrieve an iCloud-managed asset for on-device display.

CleanSwipe 是一个小型原生 SwiftUI 应用，直接使用 Apple PhotoKit，不包含第三方依赖、开发者后端、分析 SDK 或直接网络层。为了在设备端显示内容，PhotoKit 可能通过苹果服务获取仅存于 iCloud 的相册项目。

## Component map / 组件结构

```text
CleanSwipeDemoApp
└── RootView
    ├── OnboardingView       photo-access explanation / 权限说明
    ├── HomeView             task selection and settings / 任务选择与设置
    └── SwipeReviewView      card gestures and decisions / 卡片手势与选择
        ├── PhotoCardView    image and metadata presentation / 图片与元数据
        └── SummaryView      final review and confirmation / 最终复查与确认

AppViewModel                 screen state and review session / 页面状态与整理会话
├── PhotoLibraryService      authorization, fetch, image requests, deletion
└── FeedbackService          sound and haptic feedback / 声音与触感反馈
```

## Data flow / 数据流

```text
PhotoKit authorization
        ↓
Fetch PHAsset identifiers and metadata
        ↓
Display one card at a time
        ↓
Keep / delete candidate / later
        ↓
Review deletion candidates
        ↓
Explicit final confirmation
        ↓
PHPhotoLibrary.performChanges
        ↓
Apple Photos “Recently Deleted”
```

Photo bytes and metadata remain on the device. The view model retains only the information needed for the active review session. `UserDefaults` stores the chosen launch mode and processed asset identifiers so the app can avoid immediately repeating reviewed items.

照片内容和元数据保留在设备上。ViewModel 只保存当前整理会话所需的信息；`UserDefaults` 保存启动模式和已经处理过的资源标识，避免立刻重复出现已整理项目。

## Safety invariants / 安全约束

1. A swipe never deletes an asset immediately; it only marks a deletion candidate.
2. Candidates are shown again before the system deletion request.
3. PhotoKit performs the mutation only after explicit confirmation.
4. Deleted items follow Apple Photos behavior and normally enter **Recently Deleted**; the operating system and iCloud settings control final retention and synchronization.
5. Demo mode never mutates the real photo library.
6. Permission denial or limited access must not be treated as full-library access.

1. 滑动不会立即删除照片，只会加入待删除列表。
2. 系统删除请求前必须再次展示候选项目。
3. 只有用户明确确认后，才调用 PhotoKit 修改相册。
4. 删除项目按 Apple 照片的规则进入“最近删除”；最终保留时间和 iCloud 同步由系统设置决定。
5. Demo 模式绝不能修改真实相册。
6. 拒绝授权或受限访问不能被当成完整相册权限。

## Extension points / 可扩展方向

- Add tests around review-state transitions and filtering rules.
- Add localization resources instead of inline strings.
- Add optional duplicate or similarity detection that remains fully on-device.
- Keep any future telemetry strictly opt-in and update both `PRIVACY.md` and `PrivacyInfo.xcprivacy` before release.
