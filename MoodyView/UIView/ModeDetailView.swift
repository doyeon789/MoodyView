//
//  ModeDetailView.swift
//  MoodyView
//
//  Created by 도연 on 10/8/25.
//


import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ModeDetailView: View {
    @ObservedObject var appState: AppState
    @Binding var modeDetail: ModeDetail

    let onDelete: () -> Void
    let onDeleteImage: (ImageItem) -> Void
    let saveModesToDisk: () -> Void
    var onToggleIsSelected: () -> Void

    @State private var isDocumentPickerPresented = false

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(modeDetail.color)
                        .frame(width: 30, height: 30)
                    Image(systemName: modeDetail.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                Text(modeDetail.name)
                    .font(.title2)
                    .bold()

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.bordered)
            }

            if modeDetail.images.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto Wallpaper Change Interval")
                        .font(.headline)
                    HStack(alignment: .top) {
                        Stepper(
                            "\(modeDetail.changeIntervalHours)h",
                            value: $modeDetail.changeIntervalHours,
                            in: 0...23
                        )
                        .frame(width: 70)

                        Stepper(
                            "\(modeDetail.changeIntervalMinutes)m",
                            value: $modeDetail.changeIntervalMinutes,
                            in: 0...59
                        )
                        .frame(width: 60)

                        Stepper(
                            "\(modeDetail.changeIntervalSeconds)s",
                            value: $modeDetail.changeIntervalSeconds,
                            in: 0...59
                        )
                        .frame(width: 60)
                    }
                }
                .onChange(of: modeDetail.changeIntervalHours) { _ in
                    updateWallpaperIfSelected()
                }
                .onChange(of: modeDetail.changeIntervalMinutes) { _ in
                    updateWallpaperIfSelected()
                }
                .onChange(of: modeDetail.changeIntervalSeconds) { _ in
                    updateWallpaperIfSelected()
                }
                .padding(.top)
            }

            if !modeDetail.images.isEmpty {
                Text("Wallpaper Image")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(modeDetail.images) { item in
                            ZStack(alignment: .topLeading) {
                                Image(nsImage: item.image)
                                    .resizable()
                                    .frame(width: 300, height: 187.5)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )

                                HStack(spacing: 1) {
                                    Button(action: {
                                        moveImageLeft(item)
                                        if modeDetail.isSelected {
                                            let urls = modeDetail.images.map { $0.url }
                                            WallpaperManager.shared.start(
                                                for: urls,
                                                intervalHours: modeDetail.changeIntervalHours,
                                                intervalMinutes: modeDetail.changeIntervalMinutes,
                                                intervalSeconds: modeDetail.changeIntervalSeconds
                                            )
                                        }
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(
                                                Color.black.opacity(0.7)
                                            )
                                            .frame(width: 8, height: 8)
                                            .background(
                                                RoundedRectangle(
                                                    cornerRadius: 3
                                                ).fill(Color.white).shadow(
                                                    radius: 0.5
                                                ).frame(width: 19, height: 15)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: 25, height: 25)

                                    Button(action: {
                                        moveImageRight(item)
                                        if modeDetail.isSelected {
                                            let urls = modeDetail.images.map { $0.url }
                                            WallpaperManager.shared.start(
                                                for: urls,
                                                intervalHours: modeDetail.changeIntervalHours,
                                                intervalMinutes: modeDetail.changeIntervalMinutes,
                                                intervalSeconds: modeDetail.changeIntervalSeconds
                                            )
                                        }
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(
                                                Color.black.opacity(0.7)
                                            )
                                            .frame(width: 8, height: 8)
                                            .background(
                                                RoundedRectangle(
                                                    cornerRadius: 3
                                                ).fill(Color.white).shadow(
                                                    radius: 0.5
                                                ).frame(width: 19, height: 15)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: 25, height: 25)

                                    Spacer()

                                    Button(action: {
                                        onDeleteImage(item)
                                        if modeDetail.isSelected {
                                            let urls = modeDetail.images.map { $0.url }
                                            WallpaperManager.shared.start(
                                                for: urls,
                                                intervalHours: modeDetail.changeIntervalHours,
                                                intervalMinutes: modeDetail.changeIntervalMinutes,
                                                intervalSeconds: modeDetail.changeIntervalSeconds
                                            )
                                        }
                                    }) {
                                        Image(systemName: "xmark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 7, height: 7)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            .padding(4)
                                            .background(
                                                Circle().fill(Color.red)
                                                    .shadow(radius: 1)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: 25, height: 25)
                                }
                                .padding(5)
                            }
                        }
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
                    }
                }
            } else {
                Text("No Images")
                    .foregroundColor(.secondary)

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
            }

            Spacer()
            HStack(alignment: .lastTextBaseline) {
                Spacer()
                Button(action: {
                    onToggleIsSelected()
                    modeDetail = modeDetail

                    if modeDetail.isSelected {
                        let urls = modeDetail.images.map { $0.url }
                        WallpaperManager.shared.start(
                            for: urls,
                            intervalHours: modeDetail.changeIntervalHours,
                            intervalMinutes: modeDetail.changeIntervalMinutes,
                            intervalSeconds: modeDetail.changeIntervalSeconds
                        )
                    }
                    else {
                        WallpaperManager.shared.stop()
                    }
                }) {
                    Text(modeDetail.isSelected ? "Enable Mode" : "Select Mode")
                        .foregroundColor(modeDetail.isSelected ? .red : .white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                }
                .buttonStyle(PlainButtonStyle())
                .buttonStyle(PlainButtonStyle())
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(modeDetail.isSelected ? .white : .blue)
                        .shadow(radius: 1.2)
                        
                )
            }
            .onChange(of: appState.selectedModeUpdated) { _ in
                onToggleIsSelected()
                modeDetail = modeDetail
            }
        }
        .padding()
        .fileImporter(
            isPresented: $isDocumentPickerPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                addImages(urls)
                if modeDetail.isSelected {
                    let urls = modeDetail.images.map { $0.url }
                    WallpaperManager.shared.start(
                        for: urls,
                        intervalHours: modeDetail.changeIntervalHours,
                        intervalMinutes: modeDetail.changeIntervalMinutes,
                        intervalSeconds: modeDetail.changeIntervalSeconds
                    )
                }
            case .failure(let error):
                print("파일 선택 실패: \(error.localizedDescription)")
            }
        }
    }

    func addImages(_ urls: [URL]) {
        for url in urls {
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess { url.stopAccessingSecurityScopedResource() }
            }

            if let nsImage = NSImage(contentsOf: url),
                let savedFileName = ImageManager.saveImageToModeDirectory(
                    image: nsImage,
                    modeName: modeDetail.name
                )
            {
                let savedURL = ImageManager.getDocumentsDirectory(
                    forMode: modeDetail.name
                ).appendingPathComponent(savedFileName)
                modeDetail.images.append(
                    ImageItem(id: savedFileName, image: nsImage, url: savedURL)
                )
            }
        }
        modeDetail = modeDetail
        saveModesToDisk()
    }
    func moveImageLeft(_ item: ImageItem) {
        guard
            let index = modeDetail.images.firstIndex(where: { $0.id == item.id }
            ),
            index > 0
        else { return }
        modeDetail.images.swapAt(index, index - 1)
        modeDetail = modeDetail
        saveModesToDisk()
    }

    func moveImageRight(_ item: ImageItem) {
        guard
            let index = modeDetail.images.firstIndex(where: { $0.id == item.id }
            ),
            index < modeDetail.images.count - 1
        else { return }
        modeDetail.images.swapAt(index, index + 1)
        modeDetail = modeDetail
        saveModesToDisk()
    }
    func updateWallpaperIfSelected() {
        if modeDetail.isSelected {
            let urls = modeDetail.images.map { $0.url }
            WallpaperManager.shared.start(
                for: urls,
                intervalHours: modeDetail.changeIntervalHours,
                intervalMinutes: modeDetail.changeIntervalMinutes,
                intervalSeconds: modeDetail.changeIntervalSeconds
            )
        }
    }

}
