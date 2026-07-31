import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    dailyChallenge

                    VStack(alignment: .leading, spacing: 14) {
                        Text("选择一个整理任务")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.ink)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ReviewCategory.allCases) { category in
                                CategoryCard(
                                    category: category,
                                    count: viewModel.categoryCounts[category] ?? 0
                                ) {
                                    viewModel.startReview(category: category)
                                }
                            }
                        }
                    }

                    privacyNote
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(AppTheme.ink)
                    }
                    .accessibilityLabel("设置")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .presentationDetents([.medium])
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("CleanSwipe")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isDemoMode ? AppTheme.later : AppTheme.keep)
                        .frame(width: 7, height: 7)
                    Text(viewModel.isDemoMode ? "演示模式" : viewModel.authorizationLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private var dailyChallenge: some View {
        Button {
            viewModel.startReview(category: .random)
        } label: {
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 68, height: 68)
                    Image(systemName: "sparkles")
                        .font(.system(size: 27, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("今天刷 50 张")
                        .font(.title3.weight(.bold))
                    Text("大约 3 分钟 · 随机整理")
                        .font(.subheadline)
                        .opacity(0.78)
                }

                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.67, blue: 0.49), Color(red: 0.05, green: 0.48, blue: 0.44)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 26)
            )
            .shadow(color: AppTheme.keep.opacity(0.25), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(AppTheme.keep)
            Text("照片只在你的设备上处理。删除前会再次复查，确认后才移入系统“最近删除”。")
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct CategoryCard: View {
    let category: ReviewCategory
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: category.symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(category.tint)
                        .frame(width: 42, height: 42)
                        .background(category.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                    Spacer()
                    Text(count.formatted())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryInk)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text(category.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryInk)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 21))
            .overlay {
                RoundedRectangle(cornerRadius: 21)
                    .stroke(.black.opacity(0.04), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("反馈") {
                    Toggle("声音提示", isOn: $viewModel.soundEnabled)
                    Toggle("触感提示", isOn: $viewModel.hapticsEnabled)
                }

                Section("相册") {
                    LabeledContent("状态", value: viewModel.authorizationLabel)
                    if !viewModel.isDemoMode {
                        Button("打开系统权限设置") {
                            viewModel.openSettings()
                        }
                    } else {
                        Button("连接真实相册") {
                            Task { await viewModel.connectPhotoLibrary() }
                            dismiss()
                        }
                    }
                }

                Section {
                    Text("Demo 中的空间大小为估算值；系统并不直接向第三方 App 提供每张照片的精确文件大小。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("整理记录") {
                    Button("重置“已整理”记录", role: .destructive) {
                        showingResetConfirmation = true
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .confirmationDialog(
                "重新显示已经整理过的照片？",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("重置记录", role: .destructive) {
                    viewModel.resetProcessedHistory()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("这只会清除 App 内的整理进度，不会修改或删除任何照片。")
            }
        }
    }
}
