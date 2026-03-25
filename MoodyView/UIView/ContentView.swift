//
//  ContentView.swift
//  MoodyView
//
//  Created by 도연 on 10/7/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @AppStorage("selectedTheme") var selectedThemeRaw: String = "system"
    
    @EnvironmentObject var appState: AppState
    
    @State private var focusModes: [String] = []
    @State private var modeDetails: [String: ModeDetail] = [:]

    @State private var isAddingNewMode: Bool = false
    @State private var tempNewModeName: String = ""
    @State private var TitleString: String = "MoodyView"
    @State private var newMode: String = ""
    @State private var selectedColor: Color = .gray
    @State private var selectedIcon: String = "circle.fill"
    @State private var selectedImages: [ImageItem] = []
    
    @State private var tempSelectedMode: String? = nil

    let colorOptions: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple,
        .pink,
    ]
    
    var colorScheme: ColorScheme? {
        switch selectedThemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    let icons: [String] = [
        "circle.fill", "square.fill", "star.fill", "heart.fill", "bolt.fill",
        "sun.max.fill", "moon.fill", "cloud.fill", "cloud.sun.fill",
        "cloud.rain.fill",
        "arrow.up.circle.fill", "arrow.down.circle.fill", "pencil.circle.fill",
        "trash.circle.fill",
        "checkmark.circle.fill", "xmark.circle.fill", "gearshape.fill",
        "magnifyingglass.circle.fill",
        "bookmark.fill", "clock.fill", "music.note", "film",
        "gamecontroller.fill", "car.fill", "tv.fill", "app.fill",
    ]
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $tempSelectedMode) {
                    ForEach(focusModes, id: \.self) { mode in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(modeDetails[mode]?.color ?? .gray)
                                    .frame(width: 24, height: 24)
                                Image(
                                    systemName: modeDetails[mode]?.icon
                                        ?? "circle.fill"
                                )
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                            }
                            Text("\(mode)")
                        }
                    }
                    .onMove(perform: move)
                }

                Divider()

                Button("Add Mode") {
                    isAddingNewMode = true
                    tempNewModeName = ""
                    appState.selectedMode = nil
                    tempSelectedMode = nil
                }
                .padding()
            }
        } detail: {
            if isAddingNewMode {
                NewModeEditorView(
                    isAddingNewMode: $isAddingNewMode,
                    newMode: $newMode,
                    selectedColor: $selectedColor,
                    selectedIcon: $selectedIcon,
                    selectedImages: $selectedImages,
                    focusModes: $focusModes,
                    modeDetails: $modeDetails,
                    selectedMode: $appState.selectedMode,
                    colorOptions: colorOptions,
                    icons: icons,
                    onSave: { saveModesToDisk() }
                )
                // ⭐ 불필요한 onAppear 제거
            }
            else if let selected = appState.selectedMode,
                var detail = modeDetails[selected] {
                ModeDetailView(
                    appState: appState,
                    modeDetail: Binding(
                        get: { modeDetails[selected]! },
                        set: {
                            modeDetails[selected] = $0
                            saveModesToDisk()
                        }
                    ),
                    onDelete: {
                        deleteMode(named: selected)
                    },
                    onDeleteImage: { item in
                        do {
                            try FileManager.default.removeItem(at: item.url)
                        } catch {
                            print("이미지 파일 삭제 실패: \(error.localizedDescription)")
                        }
                        detail.images.removeAll { $0.id == item.id }
                        modeDetails[selected] = detail
                        saveModesToDisk()
                    },
                    saveModesToDisk: saveModesToDisk,
                    onToggleIsSelected: {
                        guard let selected = appState.selectedMode, var detail = modeDetails[selected] else { return }

                        detail.isSelected.toggle()
                        modeDetails[selected] = detail
                        for (key, var otherDetail) in modeDetails where key != selected {
                            if otherDetail.isSelected {
                                otherDetail.isSelected = false
                                modeDetails[key] = otherDetail
                            }
                        }
                        saveModesToDisk()
                    }
                )
                // ⭐ 불필요한 onAppear 제거
            }
            else {
                Text("Select Mode Or Add New Mode")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(TitleString)
        .preferredColorScheme(colorScheme)
        .onAppear {
            loadModesFromDisk()
        }
        .onChange(of: tempSelectedMode) { newValue in
            appState.selectedMode = tempSelectedMode
            
            if newValue != nil && isAddingNewMode {
                isAddingNewMode = false
            }
            
            if let newValue = newValue, let modeName = modeDetails[newValue]?.name {
                TitleString = modeName
            } else {
                TitleString = "MoodyView"
            }
        }
        .onChange(of: isAddingNewMode) { newValue in
            if newValue {
                TitleString = "Add Mode"
            } else if let selected = tempSelectedMode,
                      let modeName = modeDetails[selected]?.name {
                TitleString = modeName
            } else {
                TitleString = "MoodyView"
            }
        }
    }

    // MARK: - 저장 및 불러오기
    func saveModesToDisk() {
        var codableModeDetails: [String: CodableModeDetail] = [:]

        for (key, detail) in modeDetails {
            let imageItems = detail.images.map {
                CodableImageItem(id: $0.id, imagePath: $0.url.path)
            }
            codableModeDetails[key] = CodableModeDetail(
                name: detail.name,
                icon: detail.icon,
                colorR: detail.colorR,
                colorG: detail.colorG,
                colorB: detail.colorB,
                imageItems: imageItems,
                changeIntervalHours: detail.changeIntervalHours,
                changeIntervalMinutes: detail.changeIntervalMinutes,
                changeIntervalSeconds: detail.changeIntervalSeconds,
                isSelected: detail.isSelected
            )
        }

        let dataToSave = SavedData(
            focusModes: focusModes,
            modeDetails: codableModeDetails
        )

        do {
            let data = try JSONEncoder().encode(dataToSave)
            let url = getDocumentsDirectory().appendingPathComponent(
                "modes.json"
            )
            try data.write(to: url)
        } catch {
            print("Error saving modes: \(error)")
        }
    }

    func loadModesFromDisk() {
        let url = getDocumentsDirectory().appendingPathComponent("modes.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let data = try Data(contentsOf: url)

            if let loaded = try? JSONDecoder().decode(
                SavedData.self,
                from: data
            ) {
                focusModes = loaded.focusModes
                modeDetails = [:]

                for (key, detail) in loaded.modeDetails {
                    let imageItems = detail.imageItems.map { item in
                        let fullPath = URL(fileURLWithPath: item.imagePath)
                        guard let nsImage = NSImage(contentsOf: fullPath) else {
                            print("Failed to load image at \(fullPath.path)")
                            return ImageItem(
                                id: item.id,
                                image: NSImage(),
                                url: fullPath
                            )
                        }

                        return ImageItem(
                            id: item.id,
                            image: nsImage,
                            url: fullPath
                        )
                    }
                    modeDetails[key] = ModeDetail(
                        name: detail.name,
                        icon: detail.icon,
                        colorR: detail.colorR,
                        colorG: detail.colorG,
                        colorB: detail.colorB,
                        images: imageItems,
                        changeIntervalHours: detail.changeIntervalHours,
                        changeIntervalMinutes: detail.changeIntervalMinutes,
                        changeIntervalSeconds: detail.changeIntervalSeconds,
                        isSelected: detail.isSelected
                    )
                }
                return
            }
        } catch {
            print("Error loading modes: \(error)")
        }
    }


    func getDocumentsDirectory() -> URL {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let moodyviewURL = homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("MoodyView")

        if !fileManager.fileExists(atPath: moodyviewURL.path) {
            do {
                try fileManager.createDirectory(at: moodyviewURL, withIntermediateDirectories: true)
                print("📁 MoodyView 폴더 생성됨: \(moodyviewURL.path)")
            } catch {
                print("❌ MoodyView 폴더 생성 실패: \(error)")
            }
        }

        return moodyviewURL
    }


    func saveImageToDocumentsDirectory(image: NSImage) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "image_\(timestamp).png"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)

        guard let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            return ""
        }

        do {
            try pngData.write(to: url)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return ""
        }
    }
    
    func cancelNewModeAdding() {
        let trimmed = newMode.trimmingCharacters(in: .whitespacesAndNewlines)
        let modeName = trimmed.isEmpty ? "새 모드" : trimmed
        let sanitizedModeName = modeName.replacingOccurrences(
            of: "/",
            with: "_"
        )
        let modeDirectory = getDocumentsDirectory().appendingPathComponent(
            sanitizedModeName
        )

        if FileManager.default.fileExists(atPath: modeDirectory.path) {
            do {
                try FileManager.default.removeItem(at: modeDirectory)
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
    
    func deleteMode(named name: String) {
        focusModes.removeAll { $0 == name }
        modeDetails.removeValue(forKey: name)

        appState.selectedMode = nil
        tempSelectedMode = nil
        TitleString = "MoodyView"

        saveModesToDisk()

        let modeDirectory = getDocumentsDirectory().appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: modeDirectory.path) {
            do {
                try FileManager.default.removeItem(at: modeDirectory)
            } catch {
                print("Failed to delete mode directory: \(error)")
            }
        }
    }
    
    func addImageToSelectedMode(_ image: NSImage) {
        guard let selected = appState.selectedMode else { return }

        let fileName = saveImageToDocumentsDirectory(image: image)
        guard !fileName.isEmpty else { return }

        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        let newImageItem = ImageItem(
            id: fileName,
            image: image,
            url: url
        )

        if var detail = modeDetails[selected] {
            detail.images.append(newImageItem)
            modeDetails[selected] = detail

            saveModesToDisk()
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        focusModes.move(fromOffsets: source, toOffset: destination)
        saveModesToDisk()
    }
}
