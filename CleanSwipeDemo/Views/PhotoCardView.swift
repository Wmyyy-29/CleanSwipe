import Photos
import SwiftUI

struct PhotoCardView: View {
    let item: ReviewItem
    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    var body: some View {
        ZStack(alignment: .bottom) {
            mediaContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.04))

            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 190)
            .allowsHitTesting(false)

            metadata
        }
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(.white.opacity(0.8), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.15), radius: 20, y: 12)
        .onAppear {
            loadImage(targetSize: CGSize(width: 1_200, height: 1_600))
        }
        .onDisappear {
            PhotoLibraryService.shared.cancelImageRequest(requestID)
        }
    }

    @ViewBuilder
    private var mediaContent: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.92))
        } else if let style = item.demoStyle {
            DemoVisual(style: style)
        } else {
            ZStack {
                Color.black.opacity(0.86)
                ProgressView()
                    .tint(.white)
            }
        }
    }

    private var metadata: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                    }
                    Text(item.mediaLabel)
                        .font(.subheadline.weight(.bold))
                }

                Text(item.creationDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .opacity(0.82)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("预计 \(item.estimatedSizeText)")
                    .font(.caption.weight(.semibold))
                Text("\(item.pixelWidth) × \(item.pixelHeight)")
                    .font(.caption2.monospacedDigit())
                    .opacity(0.72)
            }
        }
        .foregroundStyle(.white)
        .padding(22)
    }

    private func loadImage(targetSize: CGSize) {
        guard !item.isDemo else { return }
        requestID = PhotoLibraryService.shared.requestImage(for: item, targetSize: targetSize) { loaded in
            image = loaded
        }
    }
}

struct DemoVisual: View {
    let style: DemoVisualStyle

    var body: some View {
        ZStack {
            LinearGradient(
                colors: style.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 300, height: 300)
                .offset(x: 110, y: -170)

            VStack(spacing: 18) {
                Image(systemName: style.symbol)
                    .font(.system(size: 100, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                Text(style.caption)
                    .font(.title2.weight(.bold))
            }
            .foregroundStyle(.white.opacity(0.92))
        }
    }
}

struct PhotoDetailView: View {
    let item: ReviewItem
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else if let style = item.demoStyle {
                        DemoVisual(style: style)
                    } else {
                        ProgressView().tint(.white)
                    }
                }
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(max(lastScale * value, 1), 5)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring) {
                        scale = scale > 1 ? 1 : 2
                        lastScale = scale
                    }
                }
            }
            .navigationTitle(item.mediaLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black.opacity(0.75), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                _ = PhotoLibraryService.shared.requestImage(
                    for: item,
                    targetSize: CGSize(width: 2_400, height: 2_400)
                ) { loaded in
                    image = loaded
                }
            }
        }
    }
}

