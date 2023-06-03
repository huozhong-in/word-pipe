import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let window: NSWindow! = self.contentView?.window
    window.delegate = self

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
extension MainFlutterWindow: NSWindowDelegate {  
  func windowWillResize(_ sender: NSWindow, to size: NSSize) -> NSSize {
    var newSize = size
    if newSize.width < 375 {
      newSize.width = 375
    }
    
    if newSize.height < 667 {
      newSize.height = 667
    } 
    return newSize          
  }
}