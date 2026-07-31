import Foundation
import Photos
import UIKit

@MainActor
final class AppViewModel: ObservableObject {
    enum Screen {
        case onboarding
        case home
        case review
        case summary
        case completed
    }

    @Published var screen: Screen = .onboarding
    @Published var selectedCategory: ReviewCategory = .random
    @Published var items: [ReviewItem] = []
    @Published var records: [ReviewRecord] = []
    @Published var currentIndex = 0
    @Published var categoryCounts: [ReviewCategory: Int] = [:]
    @Published var isDemoMode = false
    @Published var isLoading = false
    @Published var isDeleting = false
    @Published var errorMessage: String?
    @Published var soundEnabled = true {
        didSet { FeedbackService.shared.soundEnabled = soundEnabled }
    }
    @Published var hapticsEnabled = true {
        didSet { FeedbackService.shared.hapticsEnabled = hapticsEnabled }
    }

    private let photoLibrary = PhotoLibraryService.shared
    private let processedDefaultsKey = "CleanSwipe.processedAssetIdentifiers"
    private let launchModeDefaultsKey = "CleanSwipe.launchMode"
    private var processedIDs: Set<String>

    init() {
        processedIDs = Set(UserDefaults.standard.stringArray(forKey: processedDefaultsKey) ?? [])
        let savedMode = UserDefaults.standard.string(forKey: launchModeDefaultsKey)
        if savedMode == "demo" {
            isDemoMode = true
            categoryCounts = Self.demoCategoryCounts
            screen = .home
        } else if savedMode == "photos",
                  photoLibrary.authorizationStatus == .authorized ||
                  photoLibrary.authorizationStatus == .limited {
            isDemoMode = false
            screen = .home
            refreshCategoryCounts()
        }
    }

    var currentItem: ReviewItem? {
        guard currentIndex < items.count else { return nil }
        return items[currentIndex]
    }

    var nextItem: ReviewItem? {
        let nextIndex = currentIndex + 1
        guard nextIndex < items.count else { return nil }
        return items[nextIndex]
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(currentIndex) / Double(items.count)
    }

    var keptCount: Int {
        records.filter { $0.decision == .keep }.count
    }

    var deleteCount: Int {
        records.filter { $0.decision == .delete }.count
    }

    var laterCount: Int {
        records.filter { $0.decision == .later }.count
    }

    var deleteItems: [ReviewItem] {
        records.filter { $0.decision == .delete }.map(\.item)
    }

    var estimatedBytesToDelete: Int64 {
        deleteItems.reduce(0) { $0 + $1.estimatedBytes }
    }

    var favoriteDeleteCount: Int {
        deleteItems.filter(\.isFavorite).count
    }

    var estimatedSpaceText: String {
        ByteCountFormatter.string(fromByteCount: estimatedBytesToDelete, countStyle: .file)
    }

    var canUndo: Bool {
        !records.isEmpty
    }

    var authorizationLabel: String {
        switch photoLibrary.authorizationStatus {
        case .authorized: "已连接全部照片"
        case .limited: "已连接部分照片"
        case .denied: "相册访问已关闭"
        case .restricted: "相册访问受系统限制"
        case .notDetermined: "尚未连接相册"
        @unknown default: "相册权限状态未知"
        }
    }

    func connectPhotoLibrary() async {
        isLoading = true
        defer { isLoading = false }

        let status: PHAuthorizationStatus
        if photoLibrary.authorizationStatus == .notDetermined {
            status = await photoLibrary.requestAuthorization()
        } else {
            status = photoLibrary.authorizationStatus
        }

        switch status {
        case .authorized, .limited:
            isDemoMode = false
            UserDefaults.standard.set("photos", forKey: launchModeDefaultsKey)
            screen = .home
            refreshCategoryCounts()
        case .denied, .restricted:
            errorMessage = "需要相册读写权限才能筛选和删除照片。你仍可以先体验演示模式。"
        case .notDetermined:
            break
        @unknown default:
            errorMessage = "无法读取当前相册权限。"
        }
    }

    func enterDemoMode() {
        isDemoMode = true
        UserDefaults.standard.set("demo", forKey: launchModeDefaultsKey)
        categoryCounts = Self.demoCategoryCounts
        screen = .home
    }

    func refreshCategoryCounts() {
        guard !isDemoMode else { return }
        for category in ReviewCategory.allCases {
            categoryCounts[category] = photoLibrary.itemCount(category: category)
        }
    }

    func startReview(category: ReviewCategory) {
        selectedCategory = category
        isLoading = true
        errorMessage = nil

        let fetchedItems = isDemoMode
            ? DemoData.makeItems(count: category == .today ? 18 : 50)
            : photoLibrary.fetchItems(category: category, limit: 50, excluding: processedIDs)

        items = fetchedItems
        records = []
        currentIndex = 0
        isLoading = false

        if items.isEmpty {
            errorMessage = "这个分类里暂时没有可整理的照片。"
            return
        }
        screen = .review
    }

    func decide(_ decision: ReviewDecision) {
        guard let item = currentItem else { return }
        records.append(ReviewRecord(item: item, decision: decision))
        currentIndex += 1
        FeedbackService.shared.play(for: decision)

        if currentIndex >= items.count {
            FeedbackService.shared.playSuccess()
            screen = .summary
        }
    }

    func undo() {
        guard let last = records.popLast() else { return }
        currentIndex = max(currentIndex - 1, 0)
        if currentIndex < items.count, items[currentIndex].id != last.item.id,
           let restoredIndex = items.firstIndex(where: { $0.id == last.item.id }) {
            currentIndex = restoredIndex
        }
        FeedbackService.shared.playUndo()
    }

    func toggleDeleteSelection(itemID: String) {
        guard let index = records.firstIndex(where: { $0.item.id == itemID }) else { return }
        records[index].decision = records[index].decision == .delete ? .keep : .delete
    }

    func resumeReview() {
        if currentIndex < items.count {
            screen = .review
        }
    }

    func discardSession() {
        screen = .home
        records = []
        items = []
        currentIndex = 0
    }

    func keepAllAndFinish() {
        rememberProcessed(records.filter { $0.decision != .later }.map(\.item.id))
        discardSession()
    }

    func completeWithoutDeletion() {
        rememberProcessed(records.filter { $0.decision != .later }.map(\.item.id))
        FeedbackService.shared.playSuccess()
        screen = .completed
    }

    func confirmDeletion() async {
        guard !deleteItems.isEmpty else {
            completeWithoutDeletion()
            return
        }

        isDeleting = true
        errorMessage = nil
        do {
            try await photoLibrary.delete(deleteItems)
            rememberProcessed(records.filter { $0.decision != .later }.map(\.item.id))
            isDeleting = false
            FeedbackService.shared.playSuccess()
            screen = .completed
        } catch {
            isDeleting = false
            errorMessage = error.localizedDescription
        }
    }

    func returnHome() {
        records = []
        items = []
        currentIndex = 0
        screen = .home
        if !isDemoMode {
            refreshCategoryCounts()
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func resetProcessedHistory() {
        processedIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: processedDefaultsKey)
        if !isDemoMode {
            refreshCategoryCounts()
        }
    }

    private func rememberProcessed(_ identifiers: [String]) {
        guard !isDemoMode else { return }
        processedIDs.formUnion(identifiers)
        UserDefaults.standard.set(Array(processedIDs), forKey: processedDefaultsKey)
    }

    private static var demoCategoryCounts: [ReviewCategory: Int] {
        Dictionary(uniqueKeysWithValues: ReviewCategory.allCases.map { category in
            let value: Int
            switch category {
            case .today: value = 18
            case .thisMonth: value = 126
            case .screenshots: value = 284
            case .videos: value = 43
            case .random: value = 50
            case .all: value = 2_418
            }
            return (category, value)
        })
    }
}

enum DemoData {
    static func makeItems(count: Int) -> [ReviewItem] {
        let styles: [DemoVisualStyle] = [
            .init(colors: [.orange, .pink], symbol: "sun.horizon.fill", caption: "海边的傍晚"),
            .init(colors: [.blue, .cyan], symbol: "water.waves", caption: "周末散步"),
            .init(colors: [.purple, .indigo], symbol: "sparkles", caption: "城市夜景"),
            .init(colors: [.green, .mint], symbol: "leaf.fill", caption: "公园里的树"),
            .init(colors: [.pink, .red], symbol: "birthday.cake.fill", caption: "生日聚会"),
            .init(colors: [.teal, .blue], symbol: "airplane", caption: "旅行途中"),
            .init(colors: [.yellow, .orange], symbol: "cup.and.saucer.fill", caption: "下午咖啡"),
            .init(colors: [.gray, .black], symbol: "doc.text.fill", caption: "临时截图")
        ]

        return (0..<count).map { index in
            let style = styles[index % styles.count]
            let isVideo = index % 9 == 0
            let isScreenshot = index % 8 == 7
            return ReviewItem(
                id: "demo-\(index)",
                asset: nil,
                creationDate: Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date(),
                mediaType: isVideo ? .video : .image,
                pixelWidth: isScreenshot ? 1179 : 4032,
                pixelHeight: isScreenshot ? 2556 : 3024,
                duration: isVideo ? TimeInterval(12 + index * 3) : 0,
                isFavorite: index % 11 == 0,
                isScreenshot: isScreenshot,
                demoStyle: style
            )
        }
    }
}
