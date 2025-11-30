//
//  ViewController.swift
//  QingYu
//
//  Created by QingYu Team on 2025-11-27.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 设置导航栏
        title = "轻语"
        navigationController?.navigationBar.prefersLargeTitles = true

        // 添加触觉反馈
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped)))
    }

    @objc private func viewTapped() {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }

    @IBAction func startExperienceTapped(_ sender: UIButton) {
        // 添加触觉反馈
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        // 按钮动画
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }

        // 跳转到主页
        let homeViewController = HomeViewController()
        let navigationController = UINavigationController(rootViewController: homeViewController)

        // 设置转场动画
        navigationController.modalTransitionStyle = .coverVertical
        navigationController.modalPresentationStyle = .fullScreen

        present(navigationController, animated: true) {
            print("轻语应用启动成功！")
        }
    }

    @IBAction func vinylExperienceTapped(_ sender: UIButton) {
        // 添加触觉反馈
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        // 按钮动画
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }

        // 创建演示音轨
        let demoTrack = AudioTrack(
            id: "demo_vinyl",
            title: "黑胶唱片演示",
            artist: "轻语团队",
            duration: 30,
            audioURL: URL(string: "https://example.com/demo.mp3")!,
            imageURL: nil,
            sceneTags: ["禅意静心"],
            isOffline: false,
            localPath: nil
        )

        // 直接打开播放器演示黑胶唱片交互
        let playerViewController = PlayerViewController()
        playerViewController.setTrack(demoTrack, playlist: [demoTrack], currentIndex: 0)

        let navigationController = UINavigationController(rootViewController: playerViewController)
        navigationController.modalPresentationStyle = .fullScreen

        present(navigationController, animated: true) {
            print("黑胶唱片体验启动成功！")
        }
    }
}