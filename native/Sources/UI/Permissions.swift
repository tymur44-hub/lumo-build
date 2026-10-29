import SwiftUI
import AVFoundation
import Photos
import Speech
import Contacts
import UserNotifications

/// Первый запуск: сразу просим всё, что понадобится приложению
struct PermissionsView: View {
    var onDone: () -> Void
    @State private var busy = false

    private let items: [(String, Color, String, String)] = [
        ("bell.fill", Color(hex: 0xff5b5b), "Уведомления", "Сообщения и звонки, когда Lumo свёрнут"),
        ("camera.fill", Color(hex: 0x2b8cff), "Камера", "Фото, видеосообщения и видеозвонки"),
        ("mic.fill", Color(hex: 0xa35bff), "Микрофон", "Голосовые сообщения и звонки"),
        ("photo.fill", Color(hex: 0x2bd67b), "Фото", "Отправка и сохранение фото и видео"),
        ("person.2.fill", Color(hex: 0xff8a3d), "Контакты", "Найти друзей, которые уже в Lumo"),
        ("waveform", Color(hex: 0x5b6cff), "Распознавание речи", "Текст под голосовыми сообщениями"),
    ]

    var body: some View {
        ZStack {
            AuroraBackground(intensity: 0.4, speed: 0.6, base: Theme.bg, dim: 0).ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 14) {
                        Image("LaunchLogo").resizable().scaledToFit().frame(width: 84, height: 84).padding(.top, 40)
                        Text("Добро пожаловать в Lumo").font(.system(size: 26, weight: .heavy)).foregroundColor(Theme.text).multilineTextAlignment(.center)
                        Text("Чтобы всё работало сразу, разрешите доступ. Изменить его можно в настройках телефона.")
                            .font(.system(size: 15)).foregroundColor(Theme.muted).multilineTextAlignment(.center).padding(.horizontal, 24)
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.offset) { i, it in
                                if i > 0 { Divider().overlay(Theme.line).padding(.leading, 62) }
                                HStack(spacing: 14) {
                                    Image(systemName: it.0).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                        .frame(width: 34, height: 34).background(RoundedRectangle(cornerRadius: 10).fill(it.1))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(it.2).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                                        Text(it.3).font(.system(size: 13)).foregroundColor(Theme.muted)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14).padding(.vertical, 11)
                            }
                        }
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16).padding(.top, 8)
                    }
                }
                GradientButton(title: "Разрешить", loading: busy) { run() }.padding(.horizontal, 20)
                Button("Не сейчас") { finish() }.font(.system(size: 15, weight: .semibold)).padding(.vertical, 14)
            }
        }
    }

    private func finish() { UserDefaults.standard.set(true, forKey: "lm_perms_done"); onDone() }

    private func run() {
        busy = true
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            _ = await AVCaptureDevice.requestAccess(for: .video)
            _ = await AVCaptureDevice.requestAccess(for: .audio)
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            _ = try? await CNContactStore().requestAccess(for: .contacts)
            _ = await withCheckedContinuation { (c: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
                SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) }
            }
            await MainActor.run { busy = false; finish() }
        }
    }
}
