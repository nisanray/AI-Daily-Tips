import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Set up method channel
        if let controller = window?.rootViewController as? FlutterViewController {
            methodChannel = FlutterMethodChannel(
                name: "com.example.alarm/notifications",
                binaryMessenger: controller.binaryMessenger
            )
            
            methodChannel?.setMethodCallHandler { [weak self] (call, result) in
                self?.handleMethodCall(call, result: result)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "showNativeNotification":
            guard let args = call.arguments as? [String: Any],
                  let tipText = args["tipText"] as? String,
                  let tipId = args["tipId"] as? String,
                  let notificationId = args["notificationId"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            showNativeNotification(tipText: tipText, tipId: tipId, notificationId: notificationId)
            result(nil)
            
        case "updateNativeNotification":
            guard let args = call.arguments as? [String: Any],
                  let tipText = args["tipText"] as? String,
                  let tipId = args["tipId"] as? String,
                  let notificationId = args["notificationId"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            updateNativeNotification(tipText: tipText, tipId: tipId, notificationId: notificationId)
            result(nil)
            
        case "cancelNativeNotification":
            guard let args = call.arguments as? [String: Any],
                  let notificationId = args["notificationId"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            cancelNativeNotification(notificationId: notificationId)
            result(nil)
            
        case "getNotificationSettings":
            getNotificationSettings { settings in
                result(settings)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func showNativeNotification(tipText: String, tipId: String, notificationId: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Your Daily Tip"
        content.body = tipText
        content.sound = .default
        content.categoryIdentifier = "TIP_ACTIONS"
        
        // Add custom data
        content.userInfo = [
            "tipId": tipId,
            "tipText": tipText,
            "notificationId": notificationId
        ]
        
        // Create trigger for immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "tip_\(notificationId)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully: \(tipId)")
                self.methodChannel?.invokeMethod("onNotificationShown", arguments: [
                    "tipId": tipId,
                    "notificationId": notificationId,
                    "tipText": tipText
                ])
            }
        }
    }
    
    private func updateNativeNotification(tipText: String, tipId: String, notificationId: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Your Daily Tip (Updated)"
        content.body = tipText
        content.sound = .default
        content.categoryIdentifier = "TIP_ACTIONS"
        
        content.userInfo = [
            "tipId": tipId,
            "tipText": tipText,
            "notificationId": notificationId
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "tip_\(notificationId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error updating notification: \(error)")
            } else {
                print("Notification updated successfully: \(tipId)")
            }
        }
    }
    
    private func cancelNativeNotification(notificationId: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["tip_\(notificationId)"]
        )
        print("Notification cancelled: \(notificationId)")
    }
    
    private func getNotificationSettings(completion: @escaping ([String: Any]) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let settingsDict: [String: Any] = [
                "authorizationStatus": settings.authorizationStatus.rawValue,
                "alertSetting": settings.alertSetting.rawValue,
                "badgeSetting": settings.badgeSetting.rawValue,
                "soundSetting": settings.soundSetting.rawValue,
                "notificationCenterSetting": settings.notificationCenterSetting.rawValue,
                "lockScreenSetting": settings.lockScreenSetting.rawValue
            ]
            completion(settingsDict)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let tipId = userInfo["tipId"] as? String ?? ""
        let tipText = userInfo["tipText"] as? String ?? ""
        let notificationId = userInfo["notificationId"] as? Int ?? 0
        
        switch response.actionIdentifier {
        case "TIP_READ":
            methodChannel?.invokeMethod("onTipRead", arguments: [
                "tipId": tipId,
                "tipText": tipText,
                "notificationId": notificationId
            ])
            
        case "TIP_SHARE":
            methodChannel?.invokeMethod("onTipShare", arguments: [
                "tipId": tipId,
                "tipText": tipText
            ])
            
        case "TIP_SAVE":
            methodChannel?.invokeMethod("onTipSave", arguments: [
                "tipId": tipId,
                "tipText": tipText
            ])
            
        case "TIP_DISMISS":
            methodChannel?.invokeMethod("onTipDismiss", arguments: [
                "tipId": tipId,
                "notificationId": notificationId
            ])
            
        default:
            // Default tap action
            methodChannel?.invokeMethod("onTipRead", arguments: [
                "tipId": tipId,
                "tipText": tipText,
                "notificationId": notificationId
            ])
        }
        
        completionHandler()
  }
}
