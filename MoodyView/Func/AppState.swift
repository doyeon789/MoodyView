//
//  AppState.swift
//  MoodyView
//
//  Created by 도연 on 10/7/25.
//

import SwiftUI
import AppKit

class AppState: ObservableObject {
    @Published var modes: [ModeDetail] = []
    @Published var selectedModeUpdated: Bool = false
    @Published var selectedMode: String? = nil

    // Application Support/MoodyView/modes.json 경로 반환 (폴더 없으면 생성)
    private func getModesFileURL() throws -> URL {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let moodyviewFolderURL = appSupportURL.appendingPathComponent("MoodyView", isDirectory: true)

        if !fileManager.fileExists(atPath: moodyviewFolderURL.path) {
            try fileManager.createDirectory(at: moodyviewFolderURL, withIntermediateDirectories: true)
        }

        let fileURL = moodyviewFolderURL.appendingPathComponent("modes.json")
        return fileURL
    }

    // ⭐ ModeDataLoader의 전역 함수 사용
    func loadModes() {
        self.modes = loadModesData()
    }

    // 모드 선택 및 저장 (JSON 업데이트)
    func selectMode(_ selectedMode: ModeDetail) {
        do {
            let fileURL = try getModesFileURL()
            let data = try Data(contentsOf: fileURL)
            var decoded = try JSONDecoder().decode(SavedData.self, from: data)

            // 선택된 키 찾기
            guard
                let selectedKey = decoded.modeDetails.first(where: {
                    $0.value.name == selectedMode.name
                })?.key,
                var selectedDetail = decoded.modeDetails[selectedKey]
            else {
                print("❌ 선택된 모드를 찾을 수 없음")
                return
            }

            // 선택 상태 토글
            selectedDetail.isSelected.toggle()
            decoded.modeDetails[selectedKey] = selectedDetail

            // 나머지 모드는 선택 해제
            for (key, var otherDetail) in decoded.modeDetails where key != selectedKey {
                if otherDetail.isSelected {
                    otherDetail.isSelected = false
                    decoded.modeDetails[key] = otherDetail
                }
            }

            // JSON 저장
            let updatedData = try JSONEncoder().encode(decoded)
            try updatedData.write(to: fileURL)

            // 선택된 모드 활성화 또는 비활성화에 따라 WallpaperManager 실행/중지
            if selectedDetail.isSelected {
                let urls = selectedMode.images.map { $0.url }
                WallpaperManager.shared.start(
                    for: urls,
                    intervalHours: selectedMode.changeIntervalHours,
                    intervalMinutes: selectedMode.changeIntervalMinutes,
                    intervalSeconds: selectedMode.changeIntervalSeconds
                )
            } else {
                WallpaperManager.shared.stop()
            }

            // 다시 로드해서 UI 갱신
            loadModes()
        } catch {
            print("❌ 모드 선택 저장 실패: \(error)")
        }
    }
}
