import SwiftUI
import AppKit
import Carbon

// 自定义窗口类，允许无边框窗口成为 key window 以接收键盘输入
class LaunchpadWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    // 监听 Esc 键以隐藏窗口
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc key
            (NSApp.delegate as? AppDelegate)?.hideWindow()
        } else {
            super.keyDown(with: event)
        }
    }
}

// 应用程序代理类，负责管理 macOS 窗口生命周期
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusItem: NSStatusItem?
    var hotKeyManager: HotKeyManager?
    
    // 应用启动完成后的回调
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用为普通模式（在 Dock 栏显示图标，常驻后台）
        NSApp.setActivationPolicy(.regular)
        
        setupStatusItem()
        setupWindow()
        setupHotKey()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "square.grid.3x3.fill", accessibilityDescription: "Launchpad")
            button.action = #selector(statusItemClicked)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示/隐藏 Launchpad", action: #selector(toggleWindow), keyEquivalent: " "))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    private func setupWindow() {
        // 获取主屏幕
        let screen = NSScreen.main ?? NSScreen.screens.first!
        // 创建一个全屏、无边框的透明窗口
        let window = LaunchpadWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口层级（在菜单栏之上）
        window.level = .mainMenu + 1
        window.backgroundColor = .clear // 背景透明
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        // 设置窗口行为：可以加入所有桌面空间，支持全屏辅助
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 将 SwiftUI 视图嵌入到 NSHostingView 中作为窗口内容
        let contentView = NSHostingView(rootView: LaunchpadView())
        window.contentView = contentView
        
        self.window = window
    }
    
    private func setupHotKey() {
        // Option + Space (Option key is 524288 in Carbon modifiers, Space is 49)
        // kOptionKey = 0x0800 (2048)
        hotKeyManager = HotKeyManager(keyCode: 49, modifiers: UInt32(optionKey), callback: { [weak self] in
            DispatchQueue.main.async {
                self?.toggleWindow()
            }
        })
    }
    
    @objc func statusItemClicked() {
        toggleWindow()
    }
    
    @objc func toggleWindow() {
        guard let window = window else { return }
        if window.isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    func showWindow() {
        guard let window = window else { return }
        // 重新获取当前屏幕位置，防止屏幕分辨率或排列变化
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true)
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideWindow() {
        window?.orderOut(nil)
    }
    
    // 当所有窗口关闭时不退出应用
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
struct LaunchpadApp: App {
    // 使用 AppDelegate 来管理传统的 macOS 窗口逻辑
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 隐藏默认的设置场景
        Settings {
            EmptyView()
        }
    }
}
