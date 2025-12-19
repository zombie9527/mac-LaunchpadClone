import AppKit
import Carbon

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let callback: () -> Void
    
    init(keyCode: UInt32, modifiers: UInt32, callback: @escaping () -> Void) {
        self.callback = callback
        setupHotKey(keyCode: keyCode, modifiers: modifiers)
    }
    
    private func setupHotKey(keyCode: UInt32, modifiers: UInt32) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5357484B) // 'SWHK'
        hotKeyID.id = 1
        
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let ptr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let status = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.callback()
            return OSStatus(noErr)
        }, 1, [eventType], ptr, &eventHandler)
        
        if status == noErr {
            RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        }
    }
    
    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
