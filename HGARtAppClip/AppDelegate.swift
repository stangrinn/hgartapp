//
//  AppDelegate.swift
//  HGArtClip
//
//  Created by Stanislav Grinshpun on 01/04/2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = AppCompositionRoot.makeRootViewController()
        window?.makeKeyAndVisible()
        return true
    }
}
