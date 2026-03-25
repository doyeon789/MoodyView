//
//  WallpaperManager.swift
//  WallpaperManager
//
//  Created by 도연 on 5/22/25.
//

import AppKit
import UniformTypeIdentifiers

class WallpaperManager {
    
    static let shared = WallpaperManager()
    
    private var timer: Timer?
    private var currentIndex = 0
    private var images: [URL] = []
    
    // 모든 화면에 배경화면 설정 함수
    private func setWallpaper(url: URL) {
        for screen in NSScreen.screens {
            do {
                let options =
                NSWorkspace.shared.desktopImageOptions(for: screen) ?? [:]
                try NSWorkspace.shared.setDesktopImageURL(
                    url,
                    for: screen,
                    options: options
                )
            } catch {
                print("❌ 배경화면 설정 for screen \(screen): \(error)")
            }
        }
    }
    
    // 이미지 변경 시작
    func start(
        for images: [URL],
        intervalHours: Int,
        intervalMinutes: Int,
        intervalSeconds: Int
    ) {
        
        // 기존 타이머 중지
        timer?.invalidate()
        timer = nil
        currentIndex = 0
        
        // 이미지 배열이 비어있으면 복원만 수행 (이전 이미지는 유지)
        if images.isEmpty {
            print("⚠️ 이미지 목록이 비어있음, 배경화면 유지")
            return
        }
        
        self.images = images
        setWallpaper(url: images[currentIndex])
        
        // ⭐ 이미지가 1개만 있으면 타이머 불필요
        guard images.count > 1 else {
            print("ℹ️ 이미지가 1개뿐이므로 자동 변경 안 함")
            return
        }
        
        let interval = TimeInterval(
            (intervalHours * 3600) + (intervalMinutes * 60) + intervalSeconds
        )
        
        // ⭐ 최소 간격 체크
        guard interval >= 1 else {
            print("⚠️ 변경 간격이 너무 짧음 (최소 1초)")
            return
        }
        
        // ⭐ weak self로 메모리 누수 방지
        timer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            self.currentIndex = (self.currentIndex + 1) % self.images.count
            self.setWallpaper(url: self.images[self.currentIndex])
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        images = []
        currentIndex = 0
        
        let directoryPath = "\(NSHomeDirectory())/Library/Application Support/MoodyView"
        let wallpaperPath = "\(directoryPath)/wallpaper.png"
        let wallpaperURL = URL(fileURLWithPath: wallpaperPath)
        
        // wallpaper.png 파일이 존재하는지 확인
        if FileManager.default.fileExists(atPath: wallpaperPath) {
            // 🔁 두 번 호출 시도 (원본 배경화면으로 복원)
            setWallpaper(url: wallpaperURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.setWallpaper(url: wallpaperURL)
            }
            print("✅ 원본 배경화면으로 복원 완료")
        } else {
            print("⚠️ 원본 배경화면 파일(wallpaper.png)이 없습니다.")
        }
    }
}
