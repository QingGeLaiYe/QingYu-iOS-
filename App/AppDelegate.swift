//
//  AppDelegate.swift
//  QingYu
//
//  Created by QingYu Team on 2025-11-27.
//

import UIKit
import AVFoundation
import StoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 配置音频会话
        configureAudioSession()

        // 获取匿名用户标识
        configureAnonymousUserID()

        // 配置多语言
        configureLocalization()

        return true
    }

    // MARK: - Private Methods

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func configureAnonymousUserID() {
        // 使用SKPaymentQueue获取App Store Connect用户ID
        if let userID = UserDefaults.standard.string(forKey: "AnonymousUserID") {
            print("Existing Anonymous User ID: \(userID)")
        } else {
            // 生成新的匿名ID
            let anonymousID = UUID().uuidString
            UserDefaults.standard.set(anonymousID, forKey: "AnonymousUserID")
            print("Generated new Anonymous User ID: \(anonymousID)")
        }
    }

    private func configureLocalization() {
        // 检查是否已保存语言偏好
        if let languageCode = UserDefaults.standard.string(forKey: "AppLanguage") {
            // 应用保存的语言偏好
            if languageCode != "auto" {
                Bundle.setLanguage(languageCode)
            }
        } else {
            // 自动匹配系统语言
            autoDetectLanguage()
        }
    }

    private func autoDetectLanguage() {
        let systemLanguage = Locale.current.languageCode ?? "en"
        let supportedLanguages = ["zh", "en", "de", "fr"]

        if supportedLanguages.contains(systemLanguage) {
            Bundle.setLanguage(systemLanguage)
            UserDefaults.standard.set("auto", forKey: "AppLanguage")
        } else {
            // 默认使用英文
            Bundle.setLanguage("en")
            UserDefaults.standard.set("auto", forKey: "AppLanguage")
        }
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}