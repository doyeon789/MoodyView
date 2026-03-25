//
//  WindowManager.swift
//  MoodyView
//
//  Created by 도연 on 10/8/25.
//

import SwiftUI

class WindowManager {
    static let shared = WindowManager()
    var window: NSWindow?

    func showMainWindow(appState: AppState) {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = ContentView()
            .environmentObject(appState)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MoodyView"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: contentView)
        window.center()

        self.window = window
        NSApp.setActivationPolicy(.regular)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.window = nil
                NSApp.setActivationPolicy(.accessory)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.makeKeyAndOrderFront(nil)
            NSRunningApplication.current.activate(options: [.activateAllWindows]
            )
        }
    }
}
