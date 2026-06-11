import Cocoa

/// The HotkeyManager listens for system-wide keyboard events even when our app is in the background.
class HotkeyManager {
    private var eventMonitor: Any?
    
    /// Starts listening for the specific key combination.
    /// Note: Global event monitors require Accessibility permissions, which we already check for!
    func startListening(onTrigger: @escaping () -> Void) {
        // We use a global monitor to catch events outside of our application.
        let options: NSEvent.EventTypeMask = [.keyDown]
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: options) { event in
            let isCommandDown = event.modifierFlags.contains(.command)
            let isShiftDown = event.modifierFlags.contains(.shift)
            
            // KeyCode 31 represents the 'O' key on a standard US keyboard.
            // So we are listening for: Cmd + Shift + O
            if isCommandDown && isShiftDown && event.keyCode == 31 {
                print("Hotkey Triggered! Cmd + Shift + O")
                onTrigger() // Execute the optimization loop
            }
        }
    }
    
    /// Stops listening for hotkeys (useful if the user pauses the app).
    func stopListening() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
