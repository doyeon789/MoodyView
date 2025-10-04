//
//  NewModeEditorView.swift
//  NewModeEditorView
//
//  Created by 도연 on 5/15/25.
//

import AppKit
import SwiftUI

extension Color {
    func toRGB() -> (r: Int, g: Int, b: Int)? {
        #if canImport(UIKit)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)
            return (Int(red * 255), Int(green * 255), Int(blue * 255))
        #elseif canImport(AppKit)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            NSColor(self).usingColorSpace(.deviceRGB)?
                .getRed(&red, green: &green, blue: &blue, alpha: nil)
            return (Int(red * 255), Int(green * 255), Int(blue * 255))
        #else
            return nil
        #endif
    }
}

struct NewModeEditorView: View {
    @AppStorage("selectedTheme") var selectedThemeRaw: String = "system"

    @Binding var isAddingNewMode: Bool
    @Binding var newMode: String
    @Binding var selectedColor: Color
    @Binding var selectedIcon: String
    @Binding var selectedImages: [ImageItem]
    @Binding var focusModes: [String]
    @Binding var modeDetails: [String: ModeDetail]
    @Binding var selectedMode: String?

    @State private var changeIntervalHours: Int = 1
    @State private var changeIntervalMinutes: Int = 0
    @State private var changeIntervalSeconds: Int = 0
    @State private var isDocumentPickerPresented = false

    let colorOptions: [Color]
    let icons: [String]

    var onSave: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Mode Name")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.trailing, 10)
                TextField("New Mode Name", text: $newMode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 100)
            }
            .padding(.top)

            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Mode Icon")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.trailing, 10)
                    ZStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 24, height: 24)
                        Image(systemName: selectedIcon)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                }

                HStack(spacing: 8) {
                    ColorPicker("", selection: $selectedColor)
                        .labelsHidden()
                        .frame(width: 30, height: 30)
                        .padding(.horizontal, 8)

                    ForEach(colorOptions, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle().stroke(
                                    Color.black.opacity(
                                        selectedColor == color ? 0.5 : 0
                                    ),
                                    lineWidth: 2
                                )
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 13))
                                .foregroundColor(
                                    selectedIcon == icon ? .white : .gray
                                )
                                .padding(8)
                                .background(
                                    Circle().fill(
                                        selectedIcon == icon
                                            ? Color.blue
                                            : Color.gray.opacity(0.2)
                                    )
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                }
            }

            VStack(alignment: .leading) {
                Text("Auto Wallpaper Change Interval")
                    .font(.headline)

                if selectedImages.count > 1 {
                    VStack(alignment: .leading) {
                        HStack {
                            Stepper(
                                "\(changeIntervalHours)h",
                                value: $changeIntervalHours,
                                in: 0...23
                            )
                            .frame(width: 100)

                            Stepper(
                                "\(changeIntervalMinutes)m",
                                value: $changeIntervalMinutes,
                                in: 0...59
                            )
                            .frame(width: 100)

                            Stepper(
                                "\(changeIntervalSeconds)s",
                                value: $changeIntervalSeconds,
                                in: 0...59
                            )
                            .frame(width: 100)
                        }

                        Text(
                            "Wallpaper Change Interval: \(changeIntervalHours)h \(changeIntervalMinutes)m \(changeIntervalSeconds)s"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    }
                } else {
                    Text("No Auto Chnage Interval If one image")
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 15) {
                Text("Select Wallpaper Image")
                    .font(.headline)

                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .frame(width: 300, height: 187.5)
                                    .foregroundColor(Color.gray.opacity(0.2))
                                Image(systemName: "plus")
                                    .font(.title2)
                            }
                            .onTapGesture {
                                isDocumentPickerPresented = true
                            }
                            ForEach(selectedImages, id: \.id) { item in
                                ZStack(alignment: .topTrailing) {
                                    Image(nsImage: item.image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 187.5)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    Color.gray,
                                                    lineWidth: 1
                                                )

                                        )
                                    Button(action: {
                                        deleteImage(item: item)
                                    }) {
                                        Image(systemName: "xmark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 8, height: 8)
                                            .foregroundColor(.red)
                                            .padding(4)
                                            .background(
                                                Circle()
                                                    .fill(Color.white)
                                                    .shadow(radius: 1)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: 25, height: 25)

                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .fileImporter(
                isPresented: $isDocumentPickerPresented,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for (index, url) in urls.enumerated() {
                        let didStartAccess =
                            url.startAccessingSecurityScopedResource()
                        defer {
                            if didStartAccess {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }

                        if let image = NSImage(contentsOf: url) {
                            let trimmed = newMode.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            let modeName = trimmed.isEmpty ? "새 모드" : trimmed

                            let imageFileName = saveImageToDocumentsDirectory(
                                image: image,
                                modeName: modeName,
                                index: selectedImages.count + index
                            )
                            let savedUrl = getDocumentsDirectory()
                                .appendingPathComponent(modeName)
                                .appendingPathComponent(imageFileName)

                            selectedImages.append(
                                ImageItem(
                                    id: imageFileName,
                                    image: image,
                                    url: savedUrl
                                )
                            )
                        }
                    }
                case .failure(let error):
                    print("File import error: \(error)")
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    let trimmed = newMode.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    let modeName = trimmed.isEmpty ? "새 모드" : trimmed
                    let sanitizedModeName = modeName.replacingOccurrences(
                        of: "/",
                        with: "_"
                    )
                    let modeDirectory = getDocumentsDirectory()
                        .appendingPathComponent(sanitizedModeName)

                    if FileManager.default.fileExists(
                        atPath: modeDirectory.path
                    ) {
                        do {
                            try FileManager.default.removeItem(
                                at: modeDirectory
                            )
                        } catch {
                            print("Failed to delete mode directory: \(error)")
                        }
                    }

                    isAddingNewMode = false
                    newMode = ""
                    selectedColor = .gray
                    selectedIcon = "circle.fill"
                    selectedImages = []
                }
                .buttonStyle(.bordered)

                Button(action: {
                    let trimmed = newMode.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    let modeName = trimmed.isEmpty ? "새 모드" : trimmed
                    guard !focusModes.contains(modeName) else { return }

                    // ⭐ 핵심 수정: 임시 폴더의 파일들을 최종 폴더로 이동/이름변경
                    let sanitizedModeName = modeName.replacingOccurrences(
                        of: "/",
                        with: "_"
                    )
                    let directoryURL = getDocumentsDirectory().appendingPathComponent(
                        sanitizedModeName
                    )

                    var imageItems: [ImageItem] = []

                    if !selectedImages.isEmpty {
                        // 목적지 폴더가 다른 경우에만 이동 처리
                        let sourceFolder = selectedImages.first?.url.deletingLastPathComponent()
                        let needsMove = sourceFolder != directoryURL
                        
                        if needsMove {
                            // 목적지 폴더 생성
                            do {
                                try FileManager.default.createDirectory(
                                    at: directoryURL,
                                    withIntermediateDirectories: true,
                                    attributes: nil
                                )
                                print("📁 Created directory: \(directoryURL.path)")
                            } catch {
                                print("❌ Failed to create directory: \(error)")
                            }
                        }
                        
                        for (index, item) in selectedImages.enumerated() {
                            let timestamp = Int(Date().timeIntervalSince1970)
                            let newFileName = "image_\(timestamp)_\(index).png"
                            let newFileURL = directoryURL.appendingPathComponent(newFileName)
                            
                            do {
                                if needsMove && FileManager.default.fileExists(atPath: item.url.path) {
                                    // 다른 폴더로 이동
                                    try FileManager.default.moveItem(at: item.url, to: newFileURL)
                                    print("✅ Moved: \(item.url.lastPathComponent) -> \(newFileName)")
                                } else if !needsMove {
                                    // 같은 폴더 내에서 이름만 변경
                                    if FileManager.default.fileExists(atPath: item.url.path) {
                                        try FileManager.default.moveItem(at: item.url, to: newFileURL)
                                        print("✅ Renamed: \(item.url.lastPathComponent) -> \(newFileName)")
                                    }
                                }
                                
                                // 새 URL로 ImageItem 생성
                                if let newImage = NSImage(contentsOf: newFileURL) {
                                    imageItems.append(
                                        ImageItem(
                                            id: newFileName,
                                            image: newImage,
                                            url: newFileURL
                                        )
                                    )
                                }
                            } catch {
                                print("❌ Failed to move/rename image: \(error)")
                            }
                        }
                        
                        // 이동 후 원본 폴더가 비어있으면 삭제
                        if needsMove, let sourceFolder = sourceFolder {
                            do {
                                let contents = try FileManager.default.contentsOfDirectory(atPath: sourceFolder.path)
                                if contents.isEmpty {
                                    try FileManager.default.removeItem(at: sourceFolder)
                                    print("🗑️ Deleted empty source folder: \(sourceFolder.path)")
                                }
                            } catch {
                                print("⚠️ Failed to clean up source folder: \(error)")
                            }
                        }
                    }

                    guard let rgb = selectedColor.toRGB() else {
                        print("Failed to convert color to RGB")
                        return
                    }

                    modeDetails[modeName] = ModeDetail(
                        name: modeName,
                        icon: selectedIcon,
                        colorR: rgb.r,
                        colorG: rgb.g,
                        colorB: rgb.b,
                        images: imageItems,
                        changeIntervalHours: changeIntervalHours,
                        changeIntervalMinutes: changeIntervalMinutes,
                        changeIntervalSeconds: changeIntervalSeconds
                    )

                    focusModes.append(modeName)
                    selectedMode = modeName
                    isAddingNewMode = false
                    newMode = ""
                    selectedColor = .gray
                    selectedIcon = "circle.fill"
                    selectedImages = []
                    onSave?()
                }) {
                    Text("Confirm")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
    }

    func saveImageToDocumentsDirectory(image: NSImage, modeName: String, index: Int)
        -> String
    {
        let sanitizedModeName = modeName.replacingOccurrences(
            of: "/",
            with: "_"
        )
        let directoryURL = getDocumentsDirectory().appendingPathComponent(
            sanitizedModeName
        )

        let timestamp = Int(Date().timeIntervalSince1970)
        let imageFileName = "image_\(timestamp)_\(index).png"
        let imageURL = directoryURL.appendingPathComponent(imageFileName)

        guard let tiffData = image.tiffRepresentation,
            let bitmapImage = NSBitmapImageRep(data: tiffData),
            let pngData = bitmapImage.representation(
                using: .png,
                properties: [:]
            )
        else {
            return ""
        }

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try pngData.write(to: imageURL)
            return imageFileName
        } catch {
            print("Error saving image: \(error)")
            return ""
        }
    }

    func getDocumentsDirectory() -> URL {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let moodyviewURL =
            homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("MoodyView")

        if !fileManager.fileExists(atPath: moodyviewURL.path) {
            do {
                try fileManager.createDirectory(
                    at: moodyviewURL,
                    withIntermediateDirectories: true
                )
                print("📁 MoodyView 폴더 생성됨: \(moodyviewURL.path)")
            } catch {
                print("❌ MoodyView 폴더 생성 실패: \(error)")
            }
        }

        return moodyviewURL
    }

    func deleteImage(item: ImageItem) {
        if let index = selectedImages.firstIndex(where: { $0.id == item.id }) {
            selectedImages.remove(at: index)
        }

        do {
            try FileManager.default.removeItem(at: item.url)
            print("Deleted image file: \(item.url)")
        } catch {
            print("Failed to delete image file: \(error)")
        }

        let folderURL = item.url.deletingLastPathComponent()
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                atPath: folderURL.path
            )
            if contents.isEmpty {
                try FileManager.default.removeItem(at: folderURL)
                print("Deleted empty folder: \(folderURL)")
            }
        } catch {
            print("Failed to check or delete folder: \(error)")
        }
    }
}
