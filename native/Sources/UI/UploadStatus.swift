import SwiftUI

/// Кольцо загрузки с процентами
struct UploadRing: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.28), lineWidth: 4)
            Circle().trim(from: 0, to: max(0.02, min(1, progress)))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.2), value: progress)
            Text("\(Int(progress * 100))%").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
        }
        .frame(width: 56, height: 56)
    }
}

/// Плитка загрузки для фото/видео: кольцо с процентами и мегабайтами
struct UploadMediaBox: View {
    let id: Int
    let w: CGFloat
    let h: CGFloat
    @EnvironmentObject var model: AppModel
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.a1.opacity(0.55), Theme.a2.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
            if let p = model.uploadProgress[id] {
                VStack(spacing: 8) {
                    UploadRing(progress: p)
                    if let b = model.uploadBytes[id] {
                        Text(Fmt.size(Int(Double(b) * p)) + " / " + Fmt.size(b))
                            .font(.system(size: 11, weight: .semibold)).foregroundColor(.white.opacity(0.95))
                    }
                }
            } else {
                ProgressView().tint(.white)
            }
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}
