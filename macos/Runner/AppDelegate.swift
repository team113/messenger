import app_links
import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  public override func application(_ application: NSApplication,
                                  continue userActivity: NSUserActivity,
                                  restorationHandler: @escaping ([any NSUserActivityRestoring]) -> Void) -> Bool {
    guard let url = AppLinks.shared.getUniversalLink(userActivity) else {
      return false
    }

    AppLinks.shared.handleLink(link: url.absoluteString)

    return false
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
