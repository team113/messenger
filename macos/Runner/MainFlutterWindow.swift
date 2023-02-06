import Cocoa
import FlutterMacOS
import window_manager

import desktop_multi_window
import medea_flutter_webrtc
import medea_jason
import path_provider_foundation

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      MedeaFlutterWebrtcPlugin.register(with: controller.registrar(forPlugin: "MedeaFlutterWebrtcPlugin"))
      MedeaJasonPlugin.register(with: controller.registrar(forPlugin: "MedeaJasonPlugin"))
      PathProviderPlugin.register(with: controller.registrar(forPlugin: "PathProviderPlugin"))
    }

    super.awakeFromNib()
  }

  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
