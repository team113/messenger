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
      name: "team113.flutter.dev/macos_utils",
      binaryMessenger: flutterViewController.engine.binaryMessenger)

    utilsChannel.setMethodCallHandler { (call, result) in
      if call.method == "cancelNotificationsContaining" {
        let args = call.arguments as! [String: Any]
        self.cancelNotificationsContaining(result: result, thread: args["thread"] as! String)
      } else if call.method == "redirectStdOut" {
        self.redirectStdOutErr()
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

  private func redirectStdOutErr() {
    // Calculate the URL of `app.log` file.
    let docs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    let url: URL = docs.appendingPathComponent("Gapopa").appendingPathComponent("app.log")

    if FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil) {
      let file = open(url.path, O_CREAT | O_WRONLY, 0o644)
      createPipeFor(port: STDOUT_FILENO, file: file)
      createPipeFor(port: STDERR_FILENO, file: file)
      print("stdout/stderr redirected to \(url.path)")
    }
  }

  /// Creates a pipe for the provided port to forward to the provided file.
  private func createPipeFor(port: Int32, file: Int32) {
    // Create a pipe.
    var stdoutPipe: [Int32] = [0, 0]
    pipe(&stdoutPipe)

    let originalStdout = dup(port)

    // Replace `stdout` with the pipe's write end.
    dup2(stdoutPipe[1], port)
    Darwin.close(stdoutPipe[1])

    // Disable buffering for logs to appear immediately.
    setbuf(stdout, nil)

    DispatchQueue.global(qos: .utility).async {
      var buffer = [UInt8](repeating: 0, count: 4096)

      while true {
        let bytesRead = read(stdoutPipe[0], &buffer, buffer.count)
        if bytesRead <= 0 {
          break
        }

        // Write to log file.
        write(file, buffer, bytesRead)

        // Write back to original `stdout`.
        write(originalStdout, buffer, bytesRead)
      }
    }
  }
}
