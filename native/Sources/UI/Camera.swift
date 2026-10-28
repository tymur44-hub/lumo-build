import SwiftUI
import AVFoundation
import UIKit

// MARK: - мой QR-код

struct MyQRView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var share = false
    @State private var scan = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    AvatarView(name: model.me?.name ?? "", url: model.me?.avatarURL, color: model.me?.color ?? 0, size: 74)
                    Text(model.me?.name ?? "").font(.title3.weight(.heavy))
                    Text("@" + (model.me?.username ?? "")).foregroundColor(Theme.muted)
                    ZStack {
                        RoundedRectangle(cornerRadius: 22).fill(Color.white)
                        if let img = QRCode.image(model.profileLink) {
                            Image(uiImage: img).interpolation(.none).resizable().scaledToFit().padding(14)
                        }
                        Image(systemName: "bubble.left.fill").font(.system(size: 20)).foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white, lineWidth: 4))
                    }
                    .frame(width: 230, height: 230)
                    .padding(.top, 10)
                }
                .padding(.vertical, 20).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [Theme.a1.opacity(0.18), Theme.a2.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                Text("Покажите код другу: он отсканирует его в Lumo (Настройки → «Сканировать QR-код») и сразу попадёт в ваш профиль.")
                    .font(.subheadline).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    Button { scan = true } label: {
                        Text("Сканировать").font(.headline).frame(maxWidth: .infinity, minHeight: 50)
                            .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(Theme.text)
                    }
                    GradientButton(title: "Поделиться") { share = true }
                }
                Spacer()
            }
            .padding(16)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Мой QR-код")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
            .sheet(isPresented: $share) { ShareSheet(items: [model.profileLink]) }
            .fullScreenCover(isPresented: $scan) { QRScanScreen().environmentObject(model) }
        }
    }
}

// MARK: - сканер QR-кодов

struct QRScanScreen: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var loginKey: String?
    @State private var handled = false

    var body: some View {
        ZStack {
            QRScannerView { code in found(code) }.ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.headline).foregroundColor(.white)
                            .frame(width: 44, height: 44).background(Circle().fill(Color.black.opacity(0.4)))
                    }
                }
                .padding(16)
                Text("Сканирование QR-кода").font(.title3.weight(.heavy)).foregroundColor(.white)
                Spacer()
                RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.92), lineWidth: 3).frame(width: 250, height: 250)
                Spacer()
                Text("Наведите камеру на QR-код профиля Lumo — или на QR-код входа на экране компьютера")
                    .font(.subheadline).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal, 30).padding(.bottom, 50)
            }
        }
        .background(Color.black)
        .alert("Войти в ваш аккаунт Lumo на компьютере?", isPresented: Binding(get: { loginKey != nil }, set: { if !$0 { loginKey = nil } })) {
            Button("Отмена", role: .cancel) {
                if let k = loginKey { Task { await model.cancelQR(key: k) } }
                dismiss()
            }
            Button("Войти") {
                if let k = loginKey { model.say("Подтверждаем вход…"); Task { await model.approveQR(key: k) } }
                dismiss()
            }
        } message: {
            Text("Подтверждайте, только если вы сами отсканировали QR-код на своём экране.")
        }
    }

    private func found(_ code: String) {
        guard !handled else { return }
        if let r = code.range(of: #"lmqr=([A-Za-z0-9_-]{16,64})"#, options: .regularExpression) {
            handled = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            loginKey = String(code[r].dropFirst(5))
            return
        }
        if let r = code.range(of: #"#@([A-Za-z0-9_]{3,32})"#, options: .regularExpression) {
            handled = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            let u = String(code[r].dropFirst(2))
            dismiss()
            Task { await model.openByUsername(u) }
            return
        }
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerVC {
        let vc = ScannerVC()
        vc.onCode = onCode
        return vc
    }

    func updateUIViewController(_ vc: ScannerVC, context: Context) {}

    final class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onCode: ((String) -> Void)?
        private let session = AVCaptureSession()
        private var preview: AVCaptureVideoPreviewLayer?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            AVCaptureDevice.requestAccess(for: .video) { @Sendable ok in
                DispatchQueue.main.async { [weak self] in if ok { self?.setup() } }
            }
        }

        private func setup() {
            guard let dev = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: dev), session.canAddInput(input) else { return }
            session.addInput(input)
            let out = AVCaptureMetadataOutput()
            guard session.canAddOutput(out) else { return }
            session.addOutput(out)
            out.setMetadataObjectsDelegate(self, queue: .main)
            out.metadataObjectTypes = [.qr]
            let p = AVCaptureVideoPreviewLayer(session: session)
            p.videoGravity = .resizeAspectFill
            p.frame = view.bounds
            view.layer.addSublayer(p)
            preview = p
            let s = session
            DispatchQueue.global(qos: .userInitiated).async { s.startRunning() }
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            preview?.frame = view.bounds
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            let s = session
            DispatchQueue.global(qos: .userInitiated).async { s.stopRunning() }
        }

        nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let o = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let s = o.stringValue else { return }
            Task { @MainActor in self.onCode?(s) }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    final class V: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var preview: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
    func makeUIView(context: Context) -> V {
        let v = V()
        v.preview.session = session
        v.preview.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ v: V, context: Context) {
        if v.preview.session !== session { v.preview.session = session }
    }
}

/// QR-код профиля другого человека; ниже — его юзернейм (нажатие копирует)
struct UserQRSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let name: String
    let username: String
    let avatar: String?
    let color: Int
    @State private var share = false
    @State private var copied = false
    @State private var appear = false

    private var link: String { "https://volshebny-mir.ru/page322172009.html#@" + username }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    AvatarView(name: name, url: avatar, color: color, size: 70)
                    Text(name).font(.title3.weight(.heavy)).foregroundColor(Theme.text)
                    ZStack {
                        RoundedRectangle(cornerRadius: 22).fill(Color.white)
                        if let img = QRCode.image(link) {
                            Image(uiImage: img).interpolation(.none).resizable().scaledToFit().padding(14)
                        }
                        Image(systemName: "person.fill").font(.system(size: 20)).foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white, lineWidth: 4))
                    }
                    .frame(width: 240, height: 240)
                    .scaleEffect(appear ? 1 : 0.85)
                    .opacity(appear ? 1 : 0)
                    .padding(.top, 8)
                    Button {
                        UIPasteboard.general.string = "@" + username
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { copied = true }
                        Task { try? await Task.sleep(nanoseconds: 1_500_000_000); withAnimation { copied = false } }
                    } label: {
                        HStack(spacing: 8) {
                            Text("@" + username).font(.system(size: 22, weight: .bold))
                            Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.a1.opacity(0.14)))
                        .shadow(color: Theme.a1.opacity(appear ? 0.45 : 0), radius: 12)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .padding(.top, 6)
                    Text(copied ? "Скопировано" : "Нажмите, чтобы скопировать").font(.footnote).foregroundColor(Theme.muted)
                }
                .padding(.vertical, 22).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [Theme.a1.opacity(0.18), Theme.a2.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                GradientButton(title: "Поделиться") { share = true }
                Spacer()
            }
            .padding(16)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("QR-код")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
            .sheet(isPresented: $share) { ShareSheet(items: [link]) }
            .onAppear { withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { appear = true } }
        }
    }
}
