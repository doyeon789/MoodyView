//
//  ModeDataLoader.swift
//  MoodyView
//
//  Created by 도연 on 10/8/25.
//

import Foundation
import AppKit

func loadModesData() -> [ModeDetail] {
    do {
        let appSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let fileURL = appSupportURL.appendingPathComponent("MoodyView/modes.json")
        
        let data = try Data(contentsOf: fileURL)
        let decoded = try JSONDecoder().decode(SavedData.self, from: data)
        
        let loadedModes = decoded.focusModes.compactMap { name -> ModeDetail? in
            guard let codable = decoded.modeDetails[name] else {
                return nil
            }

            let images = codable.imageItems.compactMap { item -> ImageItem? in
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
