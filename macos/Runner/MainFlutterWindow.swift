import Cocoa
import FlutterMacOS
import IOKit.ps
import UserNotifications
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let utilsChannel = FlutterMethodChannel(
      name: "tapopa.flutter.dev/_utils",
      binaryMessenger: flutterViewController.engine.binaryMessenger)

    utilsChannel.setMethodCallHandler { (call, result) in
      if call.method == "cancelNotificationsContaining" {
        let args = call.arguments as! [String: Any]
        self.cancelNotificationsContaining(result: result, thread: args["thread"] as! String)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  /// Remove the delivered notifications containing the provided thread.
  private func cancelNotificationsContaining(result: @escaping FlutterResult, thread: String) {
    if #available(macOS 10.14, *) {
      let center = UNUserNotificationCenter.current()
      center.getDeliveredNotifications { (notifications) in
        var found = false

        for notification in notifications {
          if notification.request.content.threadIdentifier.contains(thread) == true {
            center.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
            found = true
          }
        }

        result(found)
      }
    }
  }

  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
