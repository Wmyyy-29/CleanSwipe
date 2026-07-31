import Photos
import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingReviewGrid = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    summaryHeader
                    stats

                    if viewModel.deleteCount > 0 {
                        deletePreview
                    } else {
                        noDeleteState
                    }

                    safetyMessage
                    actions
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("本轮结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.resumeReview()
                    } label: {
                        Label("继续整理", systemImage: "chevron.left")
                    }
                    .disabled(viewModel.currentIndex >= viewModel.items.count)
                }
            }
            .sheet(isPresented: $showingReviewGrid) {
                DeleteReviewGrid()
            }
            .confirmationDialog(
                viewModel.isDemoMode ? "完成模拟删除？" : "将这些项目移到“最近删除”？",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    viewModel.isDemoMode ? "确认模拟删除" : "确认删除 \(viewModel.deleteCount) 个项目",
                    role: .destructive
                ) {
                    Task { await viewModel.confirmDeletion() }
                }
                Button("取消", role: .cancel) {}
            } message: {
                if viewModel.isDemoMode {
                    Text("演示模式不会修改你的真实相册。")
                } else if viewModel.favoriteDeleteCount > 0 {
                    Text("注意：其中有 \(viewModel.favoriteDeleteCount) 张已收藏照片。iOS 可能再次显示系统确认。")
                } else {
                    Text("iOS 可能再次显示系统确认。删除后的照片通常会在系统“最近删除”保留 30 天。")
                }
            }
            .overlay {
                if viewModel.isDeleting {
                    ZStack {
                        Color.black.opacity(0.22).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("正在提交到系统相册…")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.keep.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(AppTheme.keep)
            }

            Text("整理得不错")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            Text("你已经检查了 \(viewModel.records.count) 个项目")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            StatCard(value: "\(viewModel.keptCount)", label: "保留", color: AppTheme.keep)
            StatCard(value: "\(viewModel.deleteCount)", label: "待删除", color: AppTheme.delete)
            StatCard(value: "\(viewModel.laterCount)", label: "稍后", color: AppTheme.later)
        }
    }

    private var deletePreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("待删除清单")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("预计释放 \(viewModel.estimatedSpaceText)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer()
                Button("全部检查") {
                    showingReviewGrid = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.delete)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(viewModel.deleteItems.prefix(8))) { item in
                        SummaryThumbnail(item: item)
                            .frame(width: 82, height: 96)
                    }
                    if viewModel.deleteCount > 8 {
                        Text("+\(viewModel.deleteCount - 8)")
                            .font(.headline)
                            .foregroundStyle(AppTheme.secondaryInk)
                            .frame(width: 82, height: 96)
                            .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private var noDeleteState: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.keep)
            Text("这轮没有待删除照片")
                .font(.headline)
            Text("可以直接完成，或返回继续检查。")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private var safetyMessage: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppTheme.keep)
            Text(
                viewModel.isDemoMode
                    ? "当前是演示模式，确认操作不会影响真实照片。"
                    : "确认后由 iOS 处理删除。使用 iCloud 照片时，删除会同步到同一 Apple Account 的其他设备。"
            )
            .font(.footnote)
            .foregroundStyle(AppTheme.secondaryInk)
        }
        .padding(16)
        .background(AppTheme.keep.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                if viewModel.deleteCount > 0 {
                    showingDeleteConfirmation = true
                } else {
                    viewModel.completeWithoutDeletion()
                }
            } label: {
                HStack {
                    Text(viewModel.deleteCount > 0 ? "确认删除" : "完成本轮")
                    Spacer()
                    Image(systemName: viewModel.deleteCount > 0 ? "trash.fill" : "checkmark")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 58)
                .background(
                    viewModel.deleteCount > 0 ? AppTheme.delete : AppTheme.ink,
                    in: RoundedRectangle(cornerRadius: 18)
                )
            }

            Button("保留全部待删除项目") {
                viewModel.keepAllAndFinish()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.secondaryInk)
            .padding(.vertical, 5)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct SummaryThumbnail: View {
    let item: ReviewItem
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let style = item.demoStyle {
                LinearGradient(colors: style.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        Image(systemName: style.symbol)
                            .foregroundStyle(.white.opacity(0.85))
                    }
            } else {
                Color.black.opacity(0.08)
                    .overlay { ProgressView().controlSize(.small) }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            _ = PhotoLibraryService.shared.requestImage(
                for: item,
                targetSize: CGSize(width: 240, height: 280)
            ) { image = $0 }
        }
    }
}

struct DeleteReviewGrid: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.records) { record in
                        ReviewGridCell(record: record) {
                            viewModel.toggleDeleteSelection(itemID: record.item.id)
                        }
                    }
                }
                .padding(12)
            }
            .background(AppTheme.background)
            .navigationTitle("复查待删除")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Text("红色勾选的项目将被删除 · 当前 \(viewModel.deleteCount) 个")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct ReviewGridCell: View {
    let record: ReviewRecord
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                SummaryThumbnail(item: record.item)
                    .aspectRatio(0.82, contentMode: .fill)

                VStack(spacing: 5) {
                    Image(systemName: record.decision == .delete ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            record.decision == .delete ? Color.white : Color.white.opacity(0.85),
                            record.decision == .delete ? AppTheme.delete : Color.black.opacity(0.35)
                        )
                    if record.item.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                            .padding(5)
                            .background(.white, in: Circle())
                    }
                }
                .padding(7)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        record.decision == .delete ? AppTheme.delete : Color.clear,
                        lineWidth: 3
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

struct CompletionView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.keep.opacity(0.12))
                    .frame(width: 150, height: 150)
                Image(systemName: "sparkles")
                    .font(.system(size: 66, weight: .bold))
                    .foregroundStyle(AppTheme.keep)
            }

            VStack(spacing: 10) {
                Text("本轮完成")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(completionMessage)
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            if viewModel.deleteCount > 0 {
                Text("预计释放 \(viewModel.estimatedSpaceText)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.keep)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.keep.opacity(0.1), in: Capsule())
            }

            Spacer()

            Button {
                viewModel.returnHome()
            } label: {
                PrimaryButtonLabel(title: "返回首页", symbol: "house.fill")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private var completionMessage: String {
        if viewModel.isDemoMode {
            return "模拟流程已经完成。\n连接真实相册后即可开始实际整理。"
        }
        if viewModel.deleteCount > 0 {
            return "选中的照片已交给系统处理。\n需要恢复时，请前往照片 App 的“最近删除”。"
        }
        return "所有照片都保留下来了。\n明天再来轻松刷一组。"
    }
}
