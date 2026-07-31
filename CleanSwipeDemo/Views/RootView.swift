import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            switch viewModel.screen {
            case .onboarding:
                OnboardingView()
                    .transition(.opacity)
            case .home:
                HomeView()
                    .transition(.opacity)
            case .review:
                SwipeReviewView()
                    .transition(.move(edge: .trailing))
            case .summary:
                SummaryView()
                    .transition(.move(edge: .bottom))
            case .completed:
                CompletionView()
                    .transition(.scale.combined(with: .opacity))
            }

            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: screenIdentifier)
        .alert(
            "提示",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            if viewModel.authorizationLabel == "相册访问已关闭" {
                Button("打开设置") { viewModel.openSettings() }
            }
            Button("知道了", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var screenIdentifier: String {
        String(describing: viewModel.screen)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.16).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(AppTheme.ink)
                Text("正在准备照片…")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        }
    }
}

