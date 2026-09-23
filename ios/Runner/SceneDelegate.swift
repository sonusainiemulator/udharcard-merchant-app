import Flutter
import UIKit
import GoogleSignIn

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for urlContext in URLContexts {
      if GIDSignIn.sharedInstance.handle(urlContext.url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
