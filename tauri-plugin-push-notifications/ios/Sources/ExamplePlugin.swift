import SwiftRs
import Tauri
import UIKit
import WebKit
import UserNotifications

class PingArgs: Decodable {
  let value: String?
}

class ExamplePlugin: Plugin {
  private var pendingInvoke: Invoke?
  
  override init() {
    super.init()
    setupNotificationObservers()
  }
  
  private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didRegisterForRemoteNotifications(_:)),
      name: NSNotification.Name("DidRegisterForRemoteNotifications"),
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didFailToRegisterForRemoteNotifications(_:)),
      name: NSNotification.Name("DidFailToRegisterForRemoteNotifications"),
      object: nil
    )
  }
  
  @objc public func ping(_ invoke: Invoke) throws {
    let args = try invoke.parseArgs(PingArgs.self)
    invoke.resolve(["value": args.value ?? ""])
  }
  
  @objc public func requestDeviceToken(_ invoke: Invoke) throws {
    self.pendingInvoke = invoke
    
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if let error = error {
        invoke.reject("Failed to request notification permission: \(error.localizedDescription)")
        return
      }
      
      if granted {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      } else {
        invoke.reject("Notification permission denied")
      }
    }
  }
  
  @objc private func didRegisterForRemoteNotifications(_ notification: Notification) {
    guard let deviceToken = notification.object as? Data else { return }
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    pendingInvoke?.resolve(["deviceToken": tokenString])
    pendingInvoke = nil
  }
  
  @objc private func didFailToRegisterForRemoteNotifications(_ notification: Notification) {
    guard let error = notification.object as? Error else { return }
    pendingInvoke?.reject("Failed to register for remote notifications: \(error.localizedDescription)")
    pendingInvoke = nil
  }
}

@_cdecl("init_plugin_push_notifications")
func initPlugin() -> Plugin {
  return ExamplePlugin()
}
