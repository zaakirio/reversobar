import AppKit
import Carbon.HIToolbox

/// Registers a system-wide hotkey via Carbon (no Accessibility permission required) and invokes
/// a callback when it fires. Default binding is ⌥Space.
final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    // The Carbon handler fires on a nonisolated C callback, so the trigger must be Sendable.
    private let onTrigger: @Sendable () -> Void

    init(keyCode: UInt32 = UInt32(kVK_Space),
         modifiers: UInt32 = UInt32(optionKey),
         onTrigger: @escaping @Sendable () -> Void) {
        self.onTrigger = onTrigger
        installHandler()
        register(keyCode: keyCode, modifiers: modifiers)
    }

    private func installHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: OSType(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData -> OSStatus in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue().onTrigger()
            return noErr
        }, 1, &spec, selfPtr, &eventHandler)
    }

    private func register(keyCode: UInt32, modifiers: UInt32) {
        // Signature 'RBAR'
        let id = EventHotKeyID(signature: 0x5242_4152, id: 1)
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
