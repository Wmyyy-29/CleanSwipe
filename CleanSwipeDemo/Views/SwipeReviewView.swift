import SwiftUI

struct SwipeReviewView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showingExitConfirmation = false
    @State private var showingDetail = false

    var body: some View {
        VStack(spacing: 0) {
            reviewHeader

            GeometryReader { proxy in
                ZStack {
                    if let nextItem = viewModel.nextItem {
                        PhotoCardView(item: nextItem)
                            .scaleEffect(0.95)
                            .offset(y: 12)
                            .opacity(0.68)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                    }

                    if let item = viewModel.currentItem {
                        SwipeableCard(item: item) { decision in
                            viewModel.decide(decision)
                        } onTap: {
                            showingDetail = true
                        }
                        .id(item.id)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }

            actionBar
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 4)
        }
        .sheet(isPresented: $showingDetail) {
            if let item = viewModel.currentItem {
                PhotoDetailView(item: item)
            }
        }
        .confirmationDialog(
            "结束本轮整理？",
            isPresented: $showingExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("结束并查看结果") {
                viewModel.screen = .summary
            }
            Button("放弃本轮", role: .destructive) {
                viewModel.discardSession()
            }
            Button("继续整理", role: .cancel) {}
        } message: {
            Text("已经做出的判断可以进入汇总页复查。")
        }
    }

    private var reviewHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    showingExitConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.8), in: Circle())
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(viewModel.selectedCategory.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("\(min(viewModel.currentIndex + 1, viewModel.items.count)) / \(viewModel.items.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AppTheme.secondaryInk)
                }

                Spacer()

                Button {
                    viewModel.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.headline)
                        .foregroundStyle(viewModel.canUndo ? AppTheme.ink : AppTheme.secondaryInk.opacity(0.35))
                        .frame(width: 42, height: 42)
                        .background(.white.opacity(0.8), in: Circle())
                }
                .disabled(!viewModel.canUndo)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.08))
                    Capsule()
                        .fill(AppTheme.keep)
                        .frame(width: proxy.size.width * viewModel.progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var actionBar: some View {
        HStack(spacing: 26) {
            DecisionButton(
                title: "删除",
                symbol: "trash.fill",
                color: AppTheme.delete,
                size: 62
            ) {
                viewModel.decide(.delete)
            }

            DecisionButton(
                title: "稍后",
                symbol: "clock.fill",
                color: AppTheme.later,
                size: 50
            ) {
                viewModel.decide(.later)
            }

            DecisionButton(
                title: "保留",
                symbol: "heart.fill",
                color: AppTheme.keep,
                size: 62
            ) {
                viewModel.decide(.keep)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
}

struct SwipeableCard: View {
    let item: ReviewItem
    let onDecision: (ReviewDecision) -> Void
    let onTap: () -> Void

    @State private var offset: CGSize = .zero
    @State private var isLeaving = false

    private let horizontalThreshold: CGFloat = 105
    private let verticalThreshold: CGFloat = 90

    var body: some View {
        PhotoCardView(item: item)
            .overlay(alignment: overlayAlignment) {
                decisionStamp
                    .padding(28)
                    .opacity(stampOpacity)
            }
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 22)))
            .gesture(dragGesture)
            .onTapGesture {
                if offset == .zero {
                    onTap()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isLeaving else { return }
                offset = value.translation
            }
            .onEnded { value in
                guard !isLeaving else { return }
                let predicted = value.predictedEndTranslation

                if predicted.width > horizontalThreshold {
                    leave(.keep, destination: CGSize(width: 720, height: predicted.height))
                } else if predicted.width < -horizontalThreshold {
                    leave(.delete, destination: CGSize(width: -720, height: predicted.height))
                } else if predicted.height < -verticalThreshold {
                    leave(.later, destination: CGSize(width: predicted.width, height: -820))
                } else {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                        offset = .zero
                    }
                }
            }
    }

    private func leave(_ decision: ReviewDecision, destination: CGSize) {
        isLeaving = true
        withAnimation(.easeIn(duration: 0.18)) {
            offset = destination
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.17) {
            onDecision(decision)
        }
    }

    @ViewBuilder
    private var decisionStamp: some View {
        if offset.height < -30 && abs(offset.height) > abs(offset.width) {
            StampLabel(title: "稍后", symbol: "clock.fill", color: AppTheme.later)
        } else if offset.width >= 0 {
            StampLabel(title: "保留", symbol: "heart.fill", color: AppTheme.keep)
        } else {
            StampLabel(title: "删除", symbol: "trash.fill", color: AppTheme.delete)
        }
    }

    private var overlayAlignment: Alignment {
        if offset.height < -30 && abs(offset.height) > abs(offset.width) {
            return .bottom
        }
        return offset.width >= 0 ? .topLeading : .topTrailing
    }

    private var stampOpacity: Double {
        min(max(max(abs(offset.width), abs(offset.height)) / 95, 0), 1)
    }
}

struct StampLabel: View {
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.title3.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color, in: Capsule())
            .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
    }
}

struct DecisionButton: View {
    let title: String
    let symbol: String
    let color: Color
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: size, height: size)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.09), radius: 12, y: 7)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
