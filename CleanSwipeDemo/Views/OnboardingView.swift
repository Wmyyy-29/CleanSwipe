import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                onboardingPage(
                    eyebrow: "轻松整理",
                    title: "像刷卡一样\n清理你的相册",
                    detail: "一次只看一张。右划保留，左划加入待删除，向上稍后决定。",
                    artwork: SwipeArtwork()
                )
                .tag(0)

                onboardingPage(
                    eyebrow: "不会直接消失",
                    title: "先复查，\n再统一删除",
                    detail: "所有删除决定先进入清单。确认后才交给系统，照片仍会保留在“最近删除”中。",
                    artwork: SafetyArtwork()
                )
                .tag(1)

                onboardingPage(
                    eyebrow: "隐私优先",
                    title: "照片留在\n你的 iPhone",
                    detail: "照片读取和整理都在设备上完成。这个 Demo 不包含账号、广告或云端上传。",
                    artwork: PrivacyArtwork()
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

            VStack(spacing: 12) {
                if page < 2 {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        PrimaryButtonLabel(title: "继续", symbol: "arrow.right")
                    }
                } else {
                    Button {
                        Task { await viewModel.connectPhotoLibrary() }
                    } label: {
                        PrimaryButtonLabel(title: "连接我的相册", symbol: "photo.stack.fill")
                    }

                    Button("先体验演示模式") {
                        viewModel.enterDemoMode()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk)
                    .padding(.vertical, 6)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
        }
    }

    private func onboardingPage<Artwork: View>(
        eyebrow: String,
        title: String,
        detail: String,
        artwork: Artwork
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 30)

            artwork
                .frame(maxWidth: .infinity)
                .frame(height: 300)

            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.8)
                .foregroundStyle(AppTheme.keep)

            Text(title)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.body)
                .foregroundStyle(AppTheme.secondaryInk)
                .lineSpacing(4)

            Spacer(minLength: 80)
        }
        .padding(.horizontal, 28)
    }
}

struct SwipeArtwork: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.55))
                .frame(width: 205, height: 250)
                .rotationEffect(.degrees(-8))
                .offset(x: -35, y: 8)

            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.99, green: 0.61, blue: 0.36), .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 215, height: 270)
                .shadow(color: .black.opacity(0.15), radius: 22, y: 12)
                .overlay {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 82))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .rotationEffect(.degrees(6))

            Circle()
                .fill(AppTheme.delete)
                .frame(width: 70, height: 70)
                .overlay {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .offset(x: -125, y: 88)

            Circle()
                .fill(AppTheme.keep)
                .frame(width: 70, height: 70)
                .overlay {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .offset(x: 125, y: 88)
        }
    }
}

struct SafetyArtwork: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.keep.opacity(0.12))
                .frame(width: 260, height: 260)
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 130))
                .symbolRenderingMode(.palette)
                .foregroundStyle(AppTheme.keep, .white)
                .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
        }
    }
}

struct PrivacyArtwork: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 42)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.26, green: 0.30, blue: 0.34), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 230, height: 270)
                .shadow(color: .black.opacity(0.2), radius: 24, y: 14)
            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 68))
                Text("仅在设备上")
                    .font(.headline)
            }
            .foregroundStyle(.white)
        }
    }
}

struct PrimaryButtonLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: symbol)
        }
        .font(.headline)
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .frame(height: 58)
        .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 18))
    }
}

