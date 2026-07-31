import Photos
import UIKit

enum PhotoLibraryError: LocalizedError {
    case accessDenied
    case deletionFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            "没有相册读写权限。请在“设置”中允许访问照片。"
        case .deletionFailed:
            "照片未能删除，请稍后重试。"
        }
    }
}

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private let imageManager = PHCachingImageManager()

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func fetchItems(
        category: ReviewCategory,
        limit: Int = 50,
        excluding excludedIDs: Set<String> = []
    ) -> [ReviewItem] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeHiddenAssets = false

        let calendar = Calendar.current
        let now = Date()
        switch category {
        case .today:
            let start = calendar.startOfDay(for: now)
            options.predicate = NSPredicate(format: "creationDate >= %@", start as NSDate)
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            if let start = calendar.date(from: components) {
                options.predicate = NSPredicate(format: "creationDate >= %@", start as NSDate)
            }
        case .screenshots:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        case .videos:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        case .random, .all:
            break
        }

        let result = PHAsset.fetchAssets(with: options)
        var items: [ReviewItem] = []

        if category == .random {
            var seenCount = 0
            result.enumerateObjects { asset, _, _ in
                guard !excludedIDs.contains(asset.localIdentifier) else { return }
                seenCount += 1
                let item = ReviewItem.from(asset: asset)
                if items.count < limit {
                    items.append(item)
                } else {
                    let replacementIndex = Int.random(in: 0..<seenCount)
                    if replacementIndex < limit {
                        items[replacementIndex] = item
                    }
                }
            }
            return items.shuffled()
        }

        if category == .videos {
            result.enumerateObjects { asset, _, _ in
                guard !excludedIDs.contains(asset.localIdentifier) else { return }
                items.append(.from(asset: asset))
            }
            return Array(items.sorted { $0.duration > $1.duration }.prefix(limit))
        }

        result.enumerateObjects { asset, _, stop in
            guard !excludedIDs.contains(asset.localIdentifier) else { return }
            if category == .screenshots && !asset.mediaSubtypes.contains(.photoScreenshot) {
                return
            }
            items.append(.from(asset: asset))
            if items.count >= limit {
                stop.pointee = true
            }
        }
        return items
    }

    func itemCount(category: ReviewCategory) -> Int {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        let calendar = Calendar.current
        let now = Date()

        switch category {
        case .today:
            options.predicate = NSPredicate(
                format: "creationDate >= %@",
                calendar.startOfDay(for: now) as NSDate
            )
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            if let start = calendar.date(from: components) {
                options.predicate = NSPredicate(format: "creationDate >= %@", start as NSDate)
            }
        case .screenshots:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        case .videos:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        case .random, .all:
            break
        }
        let result = PHAsset.fetchAssets(with: options)
        if category == .screenshots {
            var count = 0
            result.enumerateObjects { asset, _, _ in
                if asset.mediaSubtypes.contains(.photoScreenshot) {
                    count += 1
                }
            }
            return count
        }
        return result.count
    }

    @discardableResult
    func requestImage(
        for item: ReviewItem,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID? {
        guard let asset = item.asset else {
            completion(nil)
            return nil
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    func cancelImageRequest(_ requestID: PHImageRequestID?) {
        guard let requestID else { return }
        imageManager.cancelImageRequest(requestID)
    }

    func delete(_ items: [ReviewItem]) async throws {
        let assets = items.compactMap(\.asset)
        guard !assets.isEmpty else {
            try await Task.sleep(nanoseconds: 450_000_000)
            return
        }

        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw PhotoLibraryError.accessDenied
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            } completionHandler: { success, error in
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.deletionFailed)
                }
            }
        }
    }
}
