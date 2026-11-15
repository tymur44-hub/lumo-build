import SwiftUI
import AVFoundation

/// Фоны карточки QR
struct QRBackground: Identifiable {
    let id: Int
    let colors: [Color]
    let dark: Bool
}

enum QRStyles {
    static let backgrounds: [QRBackground] = [
        QRBackground(id: 0, colors: [Color(hex: 0x7C5CFF), Color(hex: 0x9D7BFF)], dark: true),
        QRBackground(id: 1, colors: [Color(hex: 0xFF6EC4), Color(hex: 0xFFA84B)], dark: true),
        QRBackground(id: 2, colors: [Color(hex: 0x2BD6C6), Color(hex: 0x3A8DFF)], dark: true),
        QRBackground(id: 3, colors: [Color(hex: 0x30364D), Color(hex: 0x11141F)], dark: true),
        QRBackground(id: 4, colors: [Color(hex: 0xFFE29F), Color(hex: 0xFFA99F)], dark: false),
        QRBackground(id: 5, colors: [Color(hex: 0x56CCF2), Color(hex: 0x2F80ED)], dark: true),
        QRBackground(id: 6, colors: [Color(hex: 0xF5F7FA), Color(hex: 0xDCE3EC)], dark: false),
        QRBackground(id: 7, colors: [Color(hex: 0x11998E), Color(hex: 0x38EF7D)], dark: true),
    ]
    static let emojis = ["", "🎉", "✨", "🔥", "💜", "🌟", "😎", "🚀", "🎵", "❤️", "🌈", "👑", "💎", "🍀", "⚡️", "🦋"]
}

struct MyQRView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var share = false
    @State private var scan = false
    @State private var bg = 0
    @State private var emoji = ""
    @State private var shareImage: ShareImageItem?

    private var background: QRBackground { QRStyles.backgrounds[bg] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    qrCard.frame(maxWidth: 320).padding(.top, 8)
                    bgPicker
                    emojiPicker
                    hint
                    actions
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Мой QR-код")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
            .sheet(item: $shareImage) { it in ShareSheet(items: [it.image]) }
            .fullScreenCover(isPresented: $scan) { QRScanScreen().environmentObject(model) }
        }
    }

    private var hint: some View {
        Text("Покажите код другу — он отсканирует его в Lumo и попадёт в ваш профиль.")
            .font(.footnote).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 20)
    }

    private var bgPicker: some View {
        picker(title: "Фон") {
            ForEach(QRStyles.backgrounds) { b in
                Circle()
                    .fill(LinearGradient(colors: b.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Theme.a1, lineWidth: bg == b.id ? 3 : 0))
                    .overlay(Circle().stroke(Theme.line, lineWidth: 0.5))
                    .onTapGesture { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { bg = b.id } }
            }
        }
    }

    private var emojiPicker: some View {
        picker(title: "Эмодзи") {
            ForEach(QRStyles.emojis, id: \.self) { e in
                emojiCell(e)
            }
        }
    }

    private func emojiCell(_ e: String) -> some View {
        ZStack {
            Circle().fill(e == emoji ? Theme.a1.opacity(0.18) : Theme.panel2)
            if e.isEmpty { Image(systemName: "nosign").foregroundColor(Theme.muted) }
            else { Text(e).font(.system(size: 22)) }
        }
        .frame(width: 40, height: 40)
        .overlay(Circle().stroke(Theme.a1, lineWidth: e == emoji ? 2.5 : 0))
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { emoji = e }
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button { scan = true } label: {
                Label("Сканировать", systemImage: "qrcode.viewfinder").font(.headline).frame(maxWidth: .infinity, minHeight: 50)
                    .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(Theme.text)
            }
            Button { UIPasteboard.general.string = model.profileLink; model.say("Ссылка скопирована") } label: {
                Image(systemName: "link").font(.headline).frame(width: 54, height: 50)
                    .background(Theme.panel2, in: RoundedRectangle(cornerRadius: 16)).foregroundColor(Theme.text)
            }
            Button { renderAndShare() } label: {
                Label("Поделиться", systemImage: "square.and.arrow.up").font(.headline).frame(maxWidth: .infinity, minHeight: 50)
                    .background(LinearGradient(colors: [Theme.a1, Theme.a2], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 4)
    }

    // карточка, которую видно и которой делимся
    private var qrCard: some View {
        VStack(spacing: 12) {
            AvatarView(name: model.me?.name ?? "", url: model.me?.avatarURL, color: model.me?.color ?? 0, size: 72)
                .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 3))
            Text(model.me?.name ?? "").font(.system(size: 21, weight: .heavy)).foregroundColor(background.dark ? .white : Color(hex: 0x11141F))
            Text("@" + (model.me?.username ?? "")).font(.system(size: 15, weight: .medium)).foregroundColor(background.dark ? .white.opacity(0.85) : Color(hex: 0x11141F).opacity(0.7))
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(.white).shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                if let img = QRCode.image(model.profileLink, correction: "H") {
                    Image(uiImage: img).interpolation(.none).resizable().scaledToFit().padding(18)
                }
                Image(systemName: "bubble.left.fill").font(.system(size: 22)).foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: 15).fill(LinearGradient(colors: background.colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white, lineWidth: 4))
            }
            .frame(width: 210, height: 210)
            .overlay(alignment: .topTrailing) {
                if !emoji.isEmpty { LiquidEmoji(emoji: emoji).offset(x: 14, y: -14) }
            }
        }
        .padding(.vertical, 26).padding(.horizontal, 20).frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 30).fill(LinearGradient(colors: background.colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.15), lineWidth: 1))
    }

    @ViewBuilder private func picker<C: View>(title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted).padding(.leading, 6)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) { content() }.padding(.horizontal, 6)
            }
        }
    }

    @MainActor private func renderAndShare() {
        let card = qrCard.frame(width: 320)
        let renderer = ImageRenderer(content: card.environmentObject(model))
        renderer.scale = 3
        if let img = renderer.uiImage {
            shareImage = ShareImageItem(image: img)
        } else {
            share = true
        }
    }
}

struct ShareImageItem: Identifiable { let id = UUID(); let image: UIImage }

/// Эмодзи в «жидком стекле»: появляется каплей и мягко колышется
struct LiquidEmoji: View {
    let emoji: String
    @State private var appear = false
    @State private var wobble = false
    var body: some View {
        Text(emoji)
            .font(.system(size: 30))
            .frame(width: 56, height: 56)
            .background(
                ZStack {
                    Circle().fill(.ultraThinMaterial)
                    Circle().fill(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Circle().stroke(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                    // блик-капля
                    Ellipse().fill(.white.opacity(0.6)).frame(width: 18, height: 11).blur(radius: 3).offset(x: -8, y: -12)
                }
            )
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
            .scaleEffect(appear ? (wobble ? 1.06 : 1.0) : 0.1)
            .rotationEffect(.degrees(wobble ? 4 : -4))
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.45)) { appear = true }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.4)) { wobble = true }
            }
    }
}
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

    private var link: String { "https://lumomess.ru/#@" + username }

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
                        Task { try? await Task.sleep(nanoseconds: 1_500_000_000); withAnimation(Motion.snappy) { copied = false } }
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
