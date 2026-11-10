import SwiftUI
import UIKit

/// Переключение аккаунтов «как страница книги»: снимок старого экрана переворачивается вокруг левого края,
/// под ним уже открыт новый аккаунт.
@MainActor
final class AccountFlip: ObservableObject {
    static let shared = AccountFlip()
    @Published var page: UIImage?
    @Published var angle: Double = 0

    /// снимок текущего экрана (до переключения)
    func capture() {
        guard let w = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) else { return }
        let r = UIGraphicsImageRenderer(bounds: w.bounds)
        let im = r.image { _ in w.drawHierarchy(in: w.bounds, afterScreenUpdates: false) }
        angle = 0
        page = im
    }

    /// перевернуть страницу
    func turn() {
        guard page != nil else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.timingCurve(0.45, 0.05, 0.25, 1, duration: 0.75)) { angle = -100 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.78) {
            self.page = nil
            self.angle = 0
        }
    }
}

struct AccountFlipOverlay: View {
    @ObservedObject var flip = AccountFlip.shared

    var body: some View {
        if let im = flip.page {
            let p = min(1, abs(flip.angle) / 90)
            ZStack {
                // тень, которую «страница» отбрасывает на новый экран
                Color.black.opacity(0.35 * (1 - p)).ignoresSafeArea()
                Image(uiImage: im)
                    .resizable()
                    .ignoresSafeArea()
                    .overlay(
                        // страница темнеет и получает блик сгиба по мере поворота
                        LinearGradient(colors: [.black.opacity(0.05 + 0.45 * p), .black.opacity(0.25 * p), .white.opacity(0.12 * p)],
                                       startPoint: .leading, endPoint: .trailing)
                            .ignoresSafeArea()
                    )
                    .rotation3DEffect(.degrees(flip.angle), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.55)
                    .shadow(color: .black.opacity(0.4 * p), radius: 24, x: 10)
            }
            .allowsHitTesting(true)
            .zIndex(1000)
        }
    }
}
