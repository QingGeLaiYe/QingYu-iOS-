//
//  VinylRecordView.swift
//  QingYu
//
//  Created by QingYu Team on 2025-11-27.
//

import UIKit
import QuartzCore

protocol VinylRecordViewDelegate: AnyObject {
    func vinylRecordDidTapPlayPause(_ vinylView: VinylRecordView)
    func vinylRecordDidSwipe(_ vinylView: VinylRecordView, direction: UISwipeGestureRecognizer.Direction)
    func vinylRecordDidPan(_ vinylView: VinylRecordView, translation: CGPoint)
}

class VinylRecordView: UIView {

    // MARK: - UI Components
    private let backgroundImageView = UIImageView()
    private let vinylImageView = UIImageView()
    private let centerLabel = UIImageView()
    private let needleView = UIImageView()
    private let shineLayer = CAGradientLayer()
    private let rotationLayer = CALayer()

    // MARK: - Properties
    weak var delegate: VinylRecordViewDelegate?

    private var isPlaying: Bool = false {
        didSet {
            updateVisualState()
        }
    }

    private var rotationAngle: Double = 0.0
    private var rotationTimer: CADisplayLink?

    private let vinylRadius: CGFloat = 120
    private let centerRadius: CGFloat = 25

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
        setupVisualEffects()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupGestures()
        setupVisualEffects()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutVinylComponents()
    }

    // MARK: - Setup Methods

    private func setupViews() {
        // 设置背景
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.1)
        layer.cornerRadius = 16

        // 设置黑胶唱片背景
        backgroundImageView.backgroundColor = .black
        backgroundImageView.layer.cornerRadius = vinylRadius
        backgroundImageView.clipsToBounds = true
        backgroundImageView.contentMode = .scaleAspectFill

        // 设置黑胶唱片主视图
        vinylImageView.backgroundColor = UIColor.black
        vinylImageView.layer.cornerRadius = vinylRadius
        vinylImageView.clipsToBounds = true
        vinylImageView.contentMode = .scaleAspectFill

        // 设置中心标签
        centerLabel.backgroundColor = UIColor.red // 经典的黑胶唱片中心红色标签
        centerLabel.layer.cornerRadius = centerRadius
        centerLabel.clipsToBounds = true
        centerLabel.contentMode = .scaleAspectFit
        centerLabel.image = UIImage(systemName: "qrcode") // 可以替换为实际的国风图标

        // 设置唱针
        needleView.image = UIImage(systemName: "line.diagonal") // 简化的唱针表示
        needleView.tintColor = UIColor.systemGray2
        needleView.contentMode = .scaleAspectFit

        addSubview(backgroundImageView)
        addSubview(vinylImageView)
        addSubview(centerLabel)
        addSubview(needleView)
    }

    private func setupGestures() {
        // 点击播放/暂停
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)

        // 滑动切换曲目
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)

        // 拖动调节进度
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    private func setupVisualEffects() {
        // 设置旋转层
        rotationLayer.bounds = CGRect(x: 0, y: 0, width: vinylRadius * 2, height: vinylRadius * 2)
        rotationLayer.position = center
        rotationLayer.cornerRadius = vinylRadius
        rotationLayer.masksToBounds = true

        // 添加光泽效果
        shineLayer.frame = bounds
        shineLayer.colors = [
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.white.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ]
        shineLayer.locations = [0.0, 0.5, 1.0]
        shineLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        shineLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        shineLayer.cornerRadius = layer.cornerRadius
        shineLayer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.addSublayer(shineLayer)
    }

    private func layoutVinylComponents() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        vinylImageView.frame = CGRect(
            x: center.x - vinylRadius,
            y: center.y - vinylRadius,
            width: vinylRadius * 2,
            height: vinylRadius * 2
        )

        backgroundImageView.frame = vinylImageView.frame

        centerLabel.frame = CGRect(
            x: center.x - centerRadius,
            y: center.y - centerRadius,
            width: centerRadius * 2,
            height: centerRadius * 2
        )

        // 设置唱针位置（播放时指向唱片中心）
        let needleLength: CGFloat = 80
        let needleWidth: CGFloat = 4
        needleView.frame = CGRect(
            x: center.x + vinylRadius + 10,
            y: center.y - needleLength / 2,
            width: needleWidth,
            height: needleLength
        )

        // 更新光泽层
        shineLayer.frame = bounds
        shineLayer.cornerRadius = layer.cornerRadius
    }

    // MARK: - Public Methods

    func setPlaying(_ playing: Bool) {
        isPlaying = playing

        // 提供黑胶唱片操作的触觉反馈
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.prepare()

        if playing {
            // 唱针落下的声音效果
            feedback.impactOccurred()

            // 添加唱针动画
            animateNeedleDrop()
        } else {
            // 唱针抬起的效果
            feedback.impactOccurred()

            // 添加唱针抬起动画
            animateNeedleLift()
        }
    }

    func setVinylImage(_ image: UIImage?) {
        // 设置黑胶唱片的封面或图案
        if let image = image {
            vinylImageView.image = image
            // 添加水印效果，使其看起来像黑胶唱片
            vinylImageView.alpha = 0.85
        } else {
            // 默认黑胶纹理
            vinylImageView.image = createDefaultVinylTexture()
        }
    }

    func setCenterLabelImage(_ image: UIImage?) {
        centerLabel.image = image
    }

    func addVinylTexture() {
        // 添加黑胶唱片纹理
        let textureLayer = CALayer()
        textureLayer.frame = vinylImageView.bounds
        textureLayer.cornerRadius = vinylRadius
        textureLayer.backgroundColor = UIColor.black.cgColor

        // 添加同心圆纹理
        for i in 0..<8 {
            let ringLayer = CAShapeLayer()
            let ringRadius = vinylRadius - CGFloat(i * 15)
            let ringPath = UIBezierPath(
                arcCenter: CGPoint(x: vinylRadius, y: vinylRadius),
                radius: ringRadius,
                startAngle: 0,
                endAngle: 2 * CGFloat.pi,
                clockwise: true
            )

            ringLayer.path = ringPath.cgPath
            ringLayer.strokeColor = UIColor.darkGray.withAlphaComponent(0.3).cgColor
            ringLayer.fillColor = UIColor.clear.cgColor
            ringLayer.lineWidth = 1
            textureLayer.addSublayer(ringLayer)
        }

        vinylImageView.layer.addSublayer(textureLayer)
    }

    // MARK: - Private Methods

    private func createDefaultVinylTexture() -> UIImage? {
        let size = CGSize(width: vinylRadius * 2, height: vinylRadius * 2)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 黑色背景
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // 添加同心圆纹理
            context.setFillColor(UIColor.darkGray.withAlphaComponent(0.2).cgColor)
            for i in 0..<8 {
                let radius = vinylRadius - CGFloat(i * 15)
                let path = UIBezierPath(
                    arcCenter: CGPoint(x: vinylRadius, y: vinylRadius),
                    radius: radius,
                    startAngle: 0,
                    endAngle: 2 * CGFloat.pi,
                    clockwise: true
                )
                path.fill()
            }

            // 添加中心红色标签
            UIColor.systemRed.setFill()
            let centerPath = UIBezierPath(
                arcCenter: CGPoint(x: vinylRadius, y: vinylRadius),
                radius: centerRadius,
                startAngle: 0,
                endAngle: 2 * CGFloat.pi,
                clockwise: true
            )
            centerPath.fill()
        }
    }

    private func updateVisualState() {
        if isPlaying {
            startRotation()
            animateNeedleDrop()
        } else {
            stopRotation()
            animateNeedleLift()
        }
    }

    private func startRotation() {
        rotationTimer = CADisplayLink(target: self, selector: #selector(updateRotation))
        rotationTimer?.preferredFramesPerSecond = 60
        rotationTimer?.add(to: .main, forMode: .common)
    }

    private func stopRotation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }

    @objc private func updateRotation() {
        rotationAngle += 0.02 // 33⅓ RPM的黑胶唱片速度
        vinylImageView.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle))

        // 中心标签稍微快一点，模拟真实黑胶唱片的视觉效果
        centerLabel.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle * 1.05))
    }

    private func animateNeedleDrop() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.needleView.transform = CGAffineTransform(rotationAngle: .pi / 12)
        }
    }

    private func animateNeedleLift() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.needleView.transform = .identity
        }
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // 添加点击反馈
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        delegate?.vinylRecordDidTapPlayPause(self)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        // 添加滑动物理反馈
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        delegate?.vinylRecordDidSwipe(self, direction: gesture.direction)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        delegate?.vinylRecordDidPan(self, translation: translation)
    }

    // MARK: - Animation Effects

    func animateVinylSwap() {
        // 切换黑胶唱片时的动画效果
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.vinylImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.vinylImageView.alpha = 0.5
        } completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.vinylImageView.transform = .identity
                self.vinylImageView.alpha = 1.0
            }
        }

        // 添加旋转效果
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = CGFloat.pi * 2
        rotationAnimation.duration = 0.4
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        vinylImageView.layer.add(rotationAnimation, forKey: "swapRotation")
    }

    func animateShimmer() {
        // 黑胶唱片闪光效果
        let shimmer = CABasicAnimation(keyPath: "transform.scale.x")
        shimmer.fromValue = 1.0
        shimmer.toValue = 1.05
        shimmer.duration = 2.0
        shimmer.autoreverses = true
        shimmer.repeatCount = 1
        shimmer.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        vinylImageView.layer.add(shimmer, forKey: "shimmer")
    }
}