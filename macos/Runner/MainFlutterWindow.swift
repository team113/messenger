import Cocoa
import FlutterMacOS

import desktop_multi_window
import medea_flutter_webrtc
import medea_jason

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      MedeaFlutterWebrtcPlugin.register(with: registry.registrar(forPlugin: "MedeaFlutterWebrtcPlugin"))
      MedeaJasonPlugin.register(with: registry.registrar(forPlugin: "MedeaJasonPlugin"))
    }

    super.awakeFromNib()
  }
}
