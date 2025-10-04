//
//  MenuBarView.swift
//  menuBarView
//
//  Created by 도연 on 5/15/25.
//

import AppKit
import Cocoa
import SwiftUI
import UserNotifications

// UserDefaults 싱글톤 헬퍼 클래스
final class Settings {
    static let shared = Settings()
    private let key = "showAlertWhenWallpaperChanges"

    var showAlertWhenWallpaperChanges: Bool {
        get {
            UserDefaults.standard.bool(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

struct MenuBarView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var modes: [ModeDetail] = []
    @State private var selectedImages: [ImageItem] = []

    @State private var isSettingSelected: Bool = false
    @State private var originalWallpaperImage: NSImage? = nil

    @AppStorage("showAlertWhenWallpaperChanges") private
        var showAlertWhenWallpaperChanges: Bool = false
    {
        didSet {
            Settings.shared.showAlertWhenWallpaperChanges =
                showAlertWhenWallpaperChanges
        }
    }
    @State private var hasNotificationPermission: Bool = true

    @AppStorage("selectedTheme") var selectedThemeRaw: String = "system"

    var colorScheme: ColorScheme? {
        switch selectedThemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    private var backgroundColor: Color {
        switch selectedThemeRaw {
        case "light":
            return Color(NSColor.windowBackgroundColor).opacity(0.95)
        case "dark":
            return Color(NSColor.windowBackgroundColor).opacity(0.85)
        default:
            return Color(NSColor.windowBackgroundColor).opacity(0.9)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if !isSettingSelected {
                ScrollView {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(modes) { mode in
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        mode.isSelected
                                            ? Color.white
                                            : Color.white.opacity(0.01)
                                    )
                                    .frame(width: 230, height: 35)
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .frame(width: 24, height: 24)
                                            .foregroundStyle(mode.color)
                                        Image(systemName: mode.icon)
                                            .foregroundColor(.white)
                                            .frame(width: 24, height: 24)
                                    }
                                    .padding(.leading, 5)
                                    Text(mode.name)
                                        .font(
                                            .system(
                                                size: 14,
                                                weight: (mode.isSelected
                                                    ? .bold : .medium)
                                            )
                                        )
                                        .foregroundColor(
                                            mode.isSelected
                                                ? Color.black : Color.primary
                                        )
                                    Spacer()
                                }
                            }
                            .onTapGesture {
                                appState.selectedMode = mode.name
                                appState.selectMode(mode)
                                self.modes = loadModesData()
                                appState.selectedModeUpdated.toggle()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }
                Divider()

                VStack(spacing: 5) {
                    Button(action: {
                        WindowManager.shared.showMainWindow(appState: appState)
                    
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            dismiss()
                        }
                    }) {
                        Label(
                            "Open Menu",
                            systemImage: "rectangle.and.pencil.and.ellipsis"
                        )
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(
                                Color(NSColor.windowBackgroundColor)
                            ).shadow(radius: 0.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        isSettingSelected = true
                    }) {
                        Label("Settings", systemImage: "gearshape.fill")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8).fill(
                                    Color(NSColor.windowBackgroundColor)
                                ).shadow(radius: 0.5)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 🔙 Back button
                        Button(action: {
                            isSettingSelected = false
                        }) {
                            Label("Back to Menu", systemImage: "chevron.left")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            Color(NSColor.windowBackgroundColor)
                                        )
                                        .shadow(radius: 0.5)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()

                        HStack {
                            Text("Original Wallpaper")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Button(action: {
                                selectNewWallpaper()
                            }) {
                                Text("edit")
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8).fill(
                                            Color(NSColor.windowBackgroundColor)
                                        ).shadow(radius: 0.5)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        if let nsImage = originalWallpaperImage {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .cornerRadius(8)
                                .shadow(radius: 1)
                        }

                        // 🎨 Theme Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("App Theme")
                                .font(.system(size: 13, weight: .semibold))
                            Picker("Theme", selection: $selectedThemeRaw) {
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 200)
                        }

                        // ♻️ Reset Button
                        Button(
                            role: .destructive,
                            action: {
                                print("⚠️ Settings reset triggered.")
                                selectedThemeRaw = "system"
                                updateWindowCollectionBehavior(showOnAllSpaces: false)
                            }
                        ) {
                            Label(
                                "Reset All Settings",
                                systemImage: "arrow.counterclockwise"
                            )
                        }
                        .font(.system(size: 13, weight: .medium))

                        Divider()

                        // 👤 Developer Info & Feedback
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                if let url = URL(
                                    string: "mailto:you@example.com"
                                ) {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Label("Send Feedback", systemImage: "envelope")
                            }

                            Text("Developed by 도연")
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            if let version = Bundle.main.infoDictionary?[
                                "CFBundleShortVersionString"
                            ] as? String {
                                Text("Version \(version)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // 🔌 Quit
                        Button(action: {
                            WallpaperManager.shared.stop()
                            NSApp.terminate(nil)
                        }) {
                            Label("Quit", systemImage: "power")
                                .foregroundColor(.red)
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .padding()
                }
            }
        }
        .padding(16)
        .background(VisualEffectView())
        .environment(\.colorScheme, colorScheme ?? .light)
        .frame(width: 240)
        .preferredColorScheme(colorScheme)
        .onAppear {
            self.modes = loadModesData()
            loadOriginalWallpaper()
            checkNotificationAuthorization { authorized in
                hasNotificationPermission = authorized
            }
        }
    }

    private func updateWindowCollectionBehavior(showOnAllSpaces: Bool) {
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                if showOnAllSpaces {
                    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                } else {
                    window.collectionBehavior = [.moveToActiveSpace]
                }
            }
        }
    }

    private func loadModesData() -> [ModeDetail] {
        do {
            let appSupportURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            let fileURL = appSupportURL.appendingPathComponent(
                "MoodyView/modes.json"
            )
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(SavedData.self, from: data)

            let loadedModes = decoded.focusModes.compactMap {
                name -> ModeDetail? in
                guard let codable = decoded.modeDetails[name] else {
                    return nil
                }

                let images = codable.imageItems.compactMap {
                    item -> ImageItem? in
                    let url = URL(fileURLWithPath: item.imagePath)
                    guard let nsImage = NSImage(contentsOf: url) else {
                        return nil
                    }
                    return ImageItem(id: item.id, image: nsImage, url: url)
                }

                return ModeDetail(
                    name: codable.name,
                    icon: codable.icon,
                    colorR: codable.colorR,
                    colorG: codable.colorG,
                    colorB: codable.colorB,
                    images: images,
                    changeIntervalHours: codable.changeIntervalHours,
                    changeIntervalMinutes: codable.changeIntervalMinutes,
                    changeIntervalSeconds: codable.changeIntervalSeconds,
                    isSelected: codable.isSelected
                )
            }

            return loadedModes
        } catch {
            print("❌ JSON 로딩 실패: \(error)")
            return []
        }
    }

    private func resizeImage(_ image: NSImage, to targetSize: NSSize)
        -> NSImage?
    {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    private func selectNewWallpaper() {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            if response == .OK, let selectedURL = panel.url {
                let screenSize: NSSize
                if let screen = NSScreen.main {
                    screenSize = screen.frame.size
                } else {
                    screenSize = NSSize(width: 1920, height: 1080)
                }

                guard let originalImage = NSImage(contentsOf: selectedURL)
                else {
                    print("❌ 이미지 열기 실패")
                    self.showError("이미지를 열 수 없습니다.")
                    return
                }

                guard let tiffData = originalImage.tiffRepresentation,
                    let bitmap = NSBitmapImageRep(data: tiffData),
                    let pngData = bitmap.representation(
                        using: .png,
                        properties: [:]
                    )
                else {
                    print("❌ PNG 변환 실패")
                    self.showError("이미지 변환에 실패했습니다.")
                    return
                }

                let folderPath =
                    "\(NSHomeDirectory())/Library/Application Support/MoodyView"
                let folderURL = URL(fileURLWithPath: folderPath)

                do {
                    try FileManager.default.createDirectory(
                        at: folderURL,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )

                    let filename = "wallpaper.png"
                    let destinationURL = folderURL.appendingPathComponent(
                        filename
                    )

                    try pngData.write(to: destinationURL)

                    DispatchQueue.main.async {
                        self.originalWallpaperImage = NSImage(
                            contentsOf: destinationURL
                        )
                        print("✅ 배경화면 저장 완료: \(filename)")
                    }

                } catch {
                    print("❌ 파일 작업 실패: \(error)")
                    DispatchQueue.main.async {
                        self.showError(
                            "파일 저장에 실패했습니다: \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "오류"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "확인")
        alert.runModal()
    }

    private func loadOriginalWallpaper() {
        let folderPath =
            "\(NSHomeDirectory())/Library/Application Support/MoodyView"
        let wallpaperURL = URL(fileURLWithPath: folderPath)
            .appendingPathComponent("wallpaper.png")

        if let image = NSImage(contentsOf: wallpaperURL) {
            self.originalWallpaperImage = image
            print("✅ 원본 배경화면 로드 완료")
        } else {
            self.originalWallpaperImage = nil
            print("ℹ️ 원본 배경화면이 설정되지 않았습니다.")
        }
    }

    func checkNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
