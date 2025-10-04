//
//  Data.swift
//  Data
//
//  Created by 도연 on 5/22/25.
//

import AppKit
import SwiftUI

struct ModeDetail: Identifiable {
    var id: String { name } // 또는 UUID 등 고유값 사용

    var name: String
    var icon: String
    var colorR: Int
    var colorG: Int
    var colorB: Int
    var images: [ImageItem] = []
    var changeIntervalHours: Int = 1
    var changeIntervalMinutes: Int = 0
    var changeIntervalSeconds: Int = 0
    var isSelected: Bool = false
    
    var color: Color {
        Color(red: Double(colorR) / 255,
              green: Double(colorG) / 255,
              blue: Double(colorB) / 255)
    }
}

struct ImageItem: Identifiable {
    let id: String
    let image: NSImage
    let url: URL
}

struct CodableImageItem: Codable {
    let id: String
    let imagePath: String
}

struct CodableModeDetail: Codable {
    var name: String
    var icon: String
    var colorR: Int
    var colorG: Int
    var colorB: Int
    var imageItems: [CodableImageItem]
    var changeIntervalHours: Int
    var changeIntervalMinutes: Int
    var changeIntervalSeconds: Int
    var isSelected: Bool
}

extension NSColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255
        self.init(calibratedRed: r, green: g, blue: b, alpha: 1.0)
    }
}

struct SavedData: Codable {
    var focusModes: [String]
    var modeDetails: [String: CodableModeDetail]
}
