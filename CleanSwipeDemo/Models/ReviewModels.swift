import Foundation
import Photos
import SwiftUI

enum ReviewDecision: String, Codable {
    case keep
    case delete
    case later

    var title: String {
        switch self {
        case .keep: "保留"
        case .delete: "待删除"
        case .later: "稍后决定"
        }
    }

    var color: Color {
        switch self {
        case .keep: AppTheme.keep
        case .delete: AppTheme.delete
        case .later: AppTheme.later
        }
    }
}

enum ReviewCategory: String, CaseIterable, Identifiable {
    case today
    case thisMonth
    case screenshots
    case videos
    case random
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "今天拍的"
        case .thisMonth: "本月照片"
        case .screenshots: "截图"
        case .videos: "大视频"
        case .random: "随机整理"
        case .all: "全部照片"
        }
    }

    var subtitle: String {
        switch self {
        case .today: "趁记忆还新鲜"
        case .thisMonth: "从最近开始"
        case .screenshots: "最容易释放空间"
        case .videos: "优先检查占用较大的视频"
        case .random: "轻松刷 50 张"
        case .all: "按时间从新到旧"
        }
    }

    var symbol: String {
        switch self {
        case .today: "sun.max.fill"
        case .thisMonth: "calendar"
        case .screenshots: "iphone.gen3"
        case .videos: "video.fill"
        case .random: "shuffle"
        case .all: "photo.on.rectangle.angled"
        }
    }

    var tint: Color {
        switch self {
        case .today: Color(red: 0.98, green: 0.65, blue: 0.24)
        case .thisMonth: Color(red: 0.36, green: 0.53, blue: 0.93)
        case .screenshots: Color(red: 0.58, green: 0.40, blue: 0.88)
        case .videos: Color(red: 0.92, green: 0.36, blue: 0.42)
        case .random: Color(red: 0.18, green: 0.70, blue: 0.62)
        case .all: Color(red: 0.28, green: 0.31, blue: 0.37)
        }
    }
}

struct ReviewItem: Identifiable {
    let id: String
    let asset: PHAsset?
    let creationDate: Date
    let mediaType: PHAssetMediaType
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval
    let isFavorite: Bool
    let isScreenshot: Bool
    let demoStyle: DemoVisualStyle?

    var isDemo: Bool { asset == nil }

    var estimatedBytes: Int64 {
        if mediaType == .video {
            return Int64(max(duration, 1) * 500_000)
        }
        return Int64(max(pixelWidth * pixelHeight, 1)) / 3
    }

    var estimatedSizeText: String {
        ByteCountFormatter.string(fromByteCount: estimatedBytes, countStyle: .file)
    }

    var mediaLabel: String {
        if mediaType == .video {
            return "视频 · \(durationText)"
        }
        if isScreenshot {
            return "截图"
        }
        return "照片"
    }

    var durationText: String {
        let totalSeconds = Int(duration.rounded())
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    static func from(asset: PHAsset) -> ReviewItem {
        ReviewItem(
            id: asset.localIdentifier,
            asset: asset,
            creationDate: asset.creationDate ?? .distantPast,
            mediaType: asset.mediaType,
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            duration: asset.duration,
            isFavorite: asset.isFavorite,
            isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
            demoStyle: nil
        )
    }
}

struct ReviewRecord: Identifiable {
    let item: ReviewItem
    var decision: ReviewDecision

    var id: String { item.id }
}

struct DemoVisualStyle {
    let colors: [Color]
    let symbol: String
    let caption: String
}

enum AppTheme {
    static let background = Color(red: 0.965, green: 0.955, blue: 0.925)
    static let surface = Color.white
    static let ink = Color(red: 0.11, green: 0.12, blue: 0.12)
    static let secondaryInk = Color(red: 0.40, green: 0.41, blue: 0.39)
    static let keep = Color(red: 0.10, green: 0.67, blue: 0.46)
    static let delete = Color(red: 0.92, green: 0.25, blue: 0.29)
    static let later = Color(red: 0.95, green: 0.64, blue: 0.18)
}

