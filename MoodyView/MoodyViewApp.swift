//
//  MoodyView_ProApp.swift
//  MoodyView
//
//  Created by 도연 on 10/7/25.
//

import SwiftUI
import ImageIO

class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        DispatchQueue.main.async {
            self.appState?.loadModes()

            guard
                let selected = self.appState?.modes.first(where: {
                    $0.isSelected
                })
            else {
                print("✅ 선택된 모드 없음")
                return
            }

            let urls = selected.images.map { $0.url }
            WallpaperManager.shared.start(
                for: urls,
                intervalHours: selected.changeIntervalHours,
                intervalMinutes: selected.changeIntervalMinutes,
                intervalSeconds: selected.changeIntervalSeconds
            )
        }
    }
}

@main
struct MoodyViewApp: App {
    @AppStorage("selectedTheme") var selectedThemeRaw: String = "system"
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appState = AppState()

    var colorScheme: ColorScheme? {
        switch selectedThemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    init() {
        appDelegate.appState = appState
        createDefaultWallpaperIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme)
        } label: {
            Image(
                nsImage: {
                    let original = NSImage(named: "MenuBarIcon")!
                    let ratio = original.size.height / original.size.width
                    let resized = NSImage(
                        size: NSSize(width: 12 / ratio, height: 12)
                    )
                    resized.lockFocus()
                    original.draw(
                        in: NSRect(origin: .zero, size: resized.size),
                        from: .zero,
                        operation: .copy,
                        fraction: 1.0
                    )
                    resized.unlockFocus()
                    resized.isTemplate = true
                    return resized
                }()
            )
        }
        .menuBarExtraStyle(.window)
    }

    private func createDefaultWallpaperIfNeeded() -> URL? {
        let baseFolder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("MoodyView")

        if !FileManager.default.fileExists(atPath: baseFolder.path) {
            do {
                try FileManager.default.createDirectory(
                    at: baseFolder,
                    withIntermediateDirectories: true
                )
            } catch {
                print("❌ 기본 폴더 생성 실패: \(error)")
                return nil
            }
        }

        // wallpaper.png 파일이 이미 존재하는지 확인
        let wallpaperURL = baseFolder.appendingPathComponent("wallpaper.png")
        if FileManager.default.fileExists(atPath: wallpaperURL.path) {
            print("✅ 기존 wallpaper.png 파일이 존재합니다: \(wallpaperURL.path)")
            return wallpaperURL
        }

        // 현재 배경화면 캡처
        guard let currentWallpaper = getCurrentWallpaper() else {
            print("❌ 현재 배경화면을 가져올 수 없습니다.")
            return createFallbackWallpaper(at: wallpaperURL)
        }

        // PNG 데이터로 변환
        guard let tiffData = currentWallpaper.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("❌ 현재 배경화면 PNG 변환 실패")
            return createFallbackWallpaper(at: wallpaperURL)
        }

        // 저장
        do {
            try pngData.write(to: wallpaperURL)
            print("✅ 현재 배경화면이 wallpaper.png로 저장됨: \(wallpaperURL.path)")
            return wallpaperURL
        } catch {
            print("❌ 배경화면 저장 실패: \(error)")
            return createFallbackWallpaper(at: wallpaperURL)
        }
    }

    // 현재 배경화면을 가져오는 함수
    private func getCurrentWallpaper() -> NSImage? {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            print("❌ 메인 스크린을 찾을 수 없습니다.")
            return nil
        }

        guard let desktopImageURL = NSWorkspace.shared.desktopImageURL(for: screen) else {
            print("⚠️ NSWorkspace로 배경화면 URL을 가져올 수 없습니다.")
            return nil
        }

        guard let imageSource = CGImageSourceCreateWithURL(desktopImageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("❌ HEIC 포함 이미지 로딩 실패")
            return nil
        }

        print("✅ CGImageSource로 현재 배경화면 가져옴")
        return NSImage(cgImage: cgImage, size: NSZeroSize)
    }

    // 대체 배경화면 생성 (현재 배경화면을 가져올 수 없을 때)
    private func createFallbackWallpaper(at url: URL) -> URL? {
        let size = NSSize(width: 2560, height: 1440)
        let image = NSImage(size: size)
        image.lockFocus()
        
        // 시스템 기본 색상 사용 (완전한 검은색 대신)
        NSColor.systemBlue.withAlphaComponent(0.1).setFill()
        NSRect(origin: .zero, size: size).fill()
        
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("❌ 대체 이미지 PNG 변환 실패")
            return nil
        }

        do {
            try pngData.write(to: url)
            print("✅ 대체 배경화면이 wallpaper.png로 저장됨")
            return url
        } catch {
            print("❌ 대체 이미지 저장 실패: \(error)")
            return nil
        }
    }
}
