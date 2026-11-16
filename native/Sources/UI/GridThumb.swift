import SwiftUI
import Photos

/// Быстрая миниатюра для сеток галереи: кэш, один размер запроса, отмена при прокрутке
enum ThumbCache {
    static let cache: NSCache<NSString, UIImage> = { let c = NSCache<NSString, UIImage>(); c.countLimit = 600; return c }()
    static let manager = PHCachingImageManager()
    static let size = CGSize(width: 260, height: 260)
    static let options: PHImageRequestOptions = {
        let o = PHImageRequestOptions()
        o.deliveryMode = .opportunistic
        o.resizeMode = .fast
        o.isNetworkAccessAllowed = true
        return o
    }()
}

struct GridThumb: View {
    let asset: PHAsset
    @State private var img: UIImage?
    @State private var req: PHImageRequestID?

    var body: some View {
        Color.clear
            .overlay {
                if let i = img { Image(uiImage: i).resizable().scaledToFill() } else { Theme.panel2 }
            }
            .clipped()
            .onAppear {
                let key = asset.localIdentifier as NSString
                if let c = ThumbCache.cache.object(forKey: key) { img = c; return }
                req = ThumbCache.manager.requestImage(for: asset, targetSize: ThumbCache.size, contentMode: .aspectFill, options: ThumbCache.options) { i, _ in
                    guard let i = i else { return }
                    ThumbCache.cache.setObject(i, forKey: key)
                    DispatchQueue.main.async { img = i }
                }
            }
            .onDisappear {
                if let r = req { ThumbCache.manager.cancelImageRequest(r); req = nil }
            }
    }
}
