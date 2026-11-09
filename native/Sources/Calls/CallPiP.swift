import UIKit
import AVKit
import AVFoundation
import WebRTC
import SwiftUI

/// Картинка в картинке для видеозвонка: свернули Lumo — видео собеседника остаётся в окошке поверх других приложений.
/// Кадры WebRTC выводятся через AVSampleBufferDisplayLayer (Metal в фоне iOS не разрешает).
final class CallPiP: NSObject, AVPictureInPictureControllerDelegate {
    static let shared = CallPiP()

    private var controller: AVPictureInPictureController?
    private var callVC: AVPictureInPictureVideoCallViewController?
    private let display = PiPDisplayView()
    private weak var source: UIView?
    private var track: RTCVideoTrack?
    private(set) var active = false

    var supported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }

    func attach(_ view: UIView) {
        guard supported, source !== view else { return }
        detachController()
        source = view
        let vc = AVPictureInPictureVideoCallViewController()
        vc.preferredContentSize = CGSize(width: 720, height: 1280)
        display.frame = vc.view.bounds
        display.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(display)
        vc.view.backgroundColor = .black
        callVC = vc
        let c = AVPictureInPictureController(contentSource: .init(activeVideoCallSourceView: view, contentViewController: vc))
        c.canStartPictureInPictureAutomaticallyFromInline = true
        c.delegate = self
        controller = c
    }

    func setTrack(_ t: RTCVideoTrack?) {
        if track === t { return }
        track?.remove(display.renderer)
        track = t
        t?.add(display.renderer)
    }

    /// кадр из запасного канала (когда прямое соединение не получилось)
    func push(_ image: UIImage) {
        guard active else { return }
        display.renderer.enqueue(image: image)
    }

    func detach() {
        setTrack(nil)
        detachController()
        source = nil
    }

    private func detachController() {
        if controller?.isPictureInPictureActive == true { controller?.stopPictureInPicture() }
        controller?.delegate = nil
        controller = nil
        display.removeFromSuperview()
        callVC = nil
        active = false
    }

    func pictureInPictureControllerWillStartPictureInPicture(_ c: AVPictureInPictureController) { active = true }
    func pictureInPictureControllerDidStopPictureInPicture(_ c: AVPictureInPictureController) { active = false }
    func pictureInPictureController(_ c: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) { active = false }
}

final class PiPDisplayView: UIView {
    override class var layerClass: AnyClass { AVSampleBufferDisplayLayer.self }
    var displayLayer: AVSampleBufferDisplayLayer { layer as! AVSampleBufferDisplayLayer }
    lazy var renderer = SampleRenderer(view: self)

    override init(frame: CGRect) {
        super.init(frame: frame)
        displayLayer.videoGravity = .resizeAspectFill
        backgroundColor = .black
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// Приёмник кадров WebRTC → CMSampleBuffer
final class SampleRenderer: NSObject, RTCVideoRenderer {
    private weak var view: PiPDisplayView?
    private var rotation: RTCVideoRotation = ._0
    private var pool: CVPixelBufferPool?
    private var poolSize: CGSize = .zero

    init(view: PiPDisplayView) { self.view = view }

    func setSize(_ size: CGSize) {}

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame, CallPiP.shared.active else { return }
        let pb: CVPixelBuffer?
        if let cv = frame.buffer as? RTCCVPixelBuffer { pb = cv.pixelBuffer } else { pb = nv12(frame.buffer.toI420()) }
        guard let pb else { return }
        if frame.rotation != rotation {
            rotation = frame.rotation
            let r = frame.rotation
            DispatchQueue.main.async { [weak self] in
                guard let v = self?.view else { return }
                let a: CGFloat = r == ._90 ? .pi / 2 : r == ._180 ? .pi : r == ._270 ? -.pi / 2 : 0
                v.transform = CGAffineTransform(rotationAngle: a)
                if let sv = v.superview { v.bounds = (r == ._90 || r == ._270) ? CGRect(x: 0, y: 0, width: sv.bounds.height, height: sv.bounds.width) : sv.bounds; v.center = CGPoint(x: sv.bounds.midX, y: sv.bounds.midY) }
            }
        }
        enqueue(pb)
    }

    func enqueue(image: UIImage) {
        guard let cg = image.cgImage else { return }
        let w = cg.width, h = cg.height
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, w, h, kCVPixelFormatType_32BGRA, [kCVPixelBufferCGImageCompatibilityKey: true, kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary, &pb)
        guard let pb else { return }
        CVPixelBufferLockBaseAddress(pb, [])
        if let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb), width: w, height: h, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
                               space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) {
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        CVPixelBufferUnlockBaseAddress(pb, [])
        enqueue(pb)
    }

    private func enqueue(_ pb: CVPixelBuffer) {
        var fmt: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pb, formatDescriptionOut: &fmt)
        guard let fmt else { return }
        var timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()), decodeTimeStamp: .invalid)
        var sb: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(allocator: nil, imageBuffer: pb, formatDescription: fmt, sampleTiming: &timing, sampleBufferOut: &sb)
        guard let sb else { return }
        if let arr = CMSampleBufferGetSampleAttachmentsArray(sb, createIfNecessary: true), CFArrayGetCount(arr) > 0 {
            let d = unsafeBitCast(CFArrayGetValueAtIndex(arr, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(d, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(), Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        DispatchQueue.main.async { [weak self] in
            guard let l = self?.view?.displayLayer else { return }
            if l.status == .failed { l.flush() }
            l.enqueue(sb)
        }
    }

    /// I420 → NV12, чтобы показать кадр программного декодера
    private func nv12(_ b: RTCI420BufferProtocol) -> CVPixelBuffer? {
        let w = Int(b.width), h = Int(b.height)
        if pool == nil || poolSize != CGSize(width: w, height: h) {
            let attrs: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                        kCVPixelBufferWidthKey as String: w, kCVPixelBufferHeightKey as String: h,
                                        kCVPixelBufferIOSurfacePropertiesKey as String: [:]]
            var p: CVPixelBufferPool?
            CVPixelBufferPoolCreate(nil, nil, attrs as CFDictionary, &p)
            pool = p; poolSize = CGSize(width: w, height: h)
        }
        guard let pool else { return nil }
        var out: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &out)
        guard let pb = out else { return nil }
        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }
        guard let yDst = CVPixelBufferGetBaseAddressOfPlane(pb, 0)?.assumingMemoryBound(to: UInt8.self),
              let uvDst = CVPixelBufferGetBaseAddressOfPlane(pb, 1)?.assumingMemoryBound(to: UInt8.self) else { return nil }
        let yStride = CVPixelBufferGetBytesPerRowOfPlane(pb, 0), uvStride = CVPixelBufferGetBytesPerRowOfPlane(pb, 1)
        for r in 0..<h { memcpy(yDst + r * yStride, b.dataY + r * Int(b.strideY), w) }
        let cw = (w + 1) / 2, ch = (h + 1) / 2
        for r in 0..<ch {
            let u = b.dataU + r * Int(b.strideU), v = b.dataV + r * Int(b.strideV)
            let d = uvDst + r * uvStride
            for c in 0..<cw { d[2 * c] = u[c]; d[2 * c + 1] = v[c] }
        }
        return pb
    }
}

/// Невидимый якорь в экране звонка: от него iOS открывает окошко «картинка в картинке»
struct PiPAnchor: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.isUserInteractionEnabled = false
        DispatchQueue.main.async { CallPiP.shared.attach(v) }
        return v
    }
    func updateUIView(_ v: UIView, context: Context) {}
    static func dismantleUIView(_ v: UIView, coordinator: ()) { CallPiP.shared.detach() }
}
