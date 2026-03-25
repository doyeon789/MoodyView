//
//  ImageManager.swift
//  MoodyView
//
//  Created by 도연 on 10/8/25.
//

import Foundation
import AppKit

struct ImageManager {
    static func saveImageToModeDirectory(image: NSImage, modeName: String) -> String? {
        let timestamp = Date().timeIntervalSince1970
        let fileName = "image_\(Int(timestamp)).png"
        let url = getDocumentsDirectory(forMode: modeName).appendingPathComponent(fileName)
        
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("❌ 이미지 변환 실패")
            return nil
        }
        
        do {
            try pngData.write(to: url)
            print("✅ 이미지 저장 완료: \(fileName)")
            return fileName
        } catch {
            print("❌ 이미지 저장 실패: \(error)")
            return nil
        }
    }
    
    static func getDocumentsDirectory(forMode modeName: String) -> URL {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser

        let baseURL = homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("MoodyView")
        
        // ⭐ 모드 이름 sanitize (파일 시스템에 안전한 이름으로 변경)
        let sanitizedName = modeName.replacingOccurrences(of: "/", with: "_")
        let modeFolderURL = baseURL.appendingPathComponent(sanitizedName, isDirectory: true)

        if !fileManager.fileExists(atPath: modeFolderURL.path) {
            do {
                try fileManager.createDirectory(at: modeFolderURL, withIntermediateDirectories: true)
                print("📁 디렉토리 생성됨: \(modeFolderURL.path)")
            } catch {
                print("❌ 디렉토리 생성 실패: \(error)")
            }
        }

        return modeFolderURL
    }
}
