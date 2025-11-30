//
//  PlayerViewController.swift
//  QingYu
//
//  Created by QingYu Team on 2025-11-27.
//

import UIKit
import AVFoundation
import MediaPlayer

class PlayerViewController: UIViewController {

    // MARK: - UI Components
    private let backgroundImageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let vinylRecordView = VinylRecordView()
    private let trackInfoLabel = UILabel()
    private let artistInfoLabel = UILabel()
    private let progressSlider = CustomSlider()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let playPauseButton = UIButton(type: .custom)
    private let previousButton = UIButton(type: .custom)
    private let nextButton = UIButton(type: .custom)
    private let modeButton = UIButton(type: .custom)
    private let backButton = UIButton(type: .custom)
    private let favoriteButton = UIButton(type: .custom)
    private let cacheButton = UIButton(type: .custom)
    private let controlsStackView = UIStackView()

    // MARK: - Properties
    private var currentTrack: AudioTrack?
    private var currentPlaylist: [AudioTrack] = []
    private var currentIndex: Int = 0
    private var isPlaying: Bool = false
    private var playbackMode: PlaybackMode = .singleLoop
    private var isFavorite: Bool = false
    private var isCached: Bool = false

    // 触觉反馈生成器
    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    private let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioNotifications()
        setupRemoteControls()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showNavigationBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutComponents()
        setupGradient()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        AudioPlayerManager.shared.delegate = nil
    }

    // MARK: - Public Methods

    func setTrack(_ track: AudioTrack, playlist: [AudioTrack], currentIndex: Int) {
        self.currentTrack = track
        self.currentPlaylist = playlist
        self.currentIndex = currentIndex

        updateTrackInfo()
        setupAudioPlayer()
        configureVinylView()
    }

    // MARK: - Setup Methods

    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupBackground()
        setupVinylRecord()
        setupTrackInfo()
        setupProgressControls()
        setupPlaybackControls()
        setupTopControls()
    }

    private func setupBackground() {
        // 模糊背景效果
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.3
        backgroundImageView.blur(radius: 20)
        view.addSubview(backgroundImageView)

        // 渐变层
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.7).cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.systemBackground.withAlphaComponent(0.9).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupVinylRecord() {
        vinylRecordView.delegate = self
        vinylRecordView.addVinylTexture()
        view.addSubview(vinylRecordView)
    }

    private func setupTrackInfo() {
        trackInfoLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        trackInfoLabel.textColor = .label
        trackInfoLabel.textAlignment = .center
        trackInfoLabel.numberOfLines = 2

        artistInfoLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        artistInfoLabel.textColor = .secondaryLabel
        artistInfoLabel.textAlignment = .center
        artistInfoLabel.numberOfLines = 1

        view.addSubview(trackInfoLabel)
        view.addSubview(artistInfoLabel)
    }

    private func setupProgressControls() {
        // 自定义进度条，模拟唱臂效果
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.minimumTrackTintColor = .systemBlue
        progressSlider.maximumTrackTintColor = .systemGray5
        progressSlider.thumbTintColor = .white
        progressSlider.addTarget(self, action: #selector(progressSliderValueChanged), for: .valueChanged)

        // 设置进度条的轨道高度
        progressSlider.trackHeight = 4
        progressSlider.thumbSize = CGSize(width: 20, height: 20)

        currentTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        currentTimeLabel.textColor = .secondaryLabel

        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        durationLabel.textColor = .secondaryLabel

        view.addSubview(progressSlider)
        view.addSubview(currentTimeLabel)
        view.addSubview(durationLabel)
    }

    private func setupPlaybackControls() {
        // 返回按钮
        backButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        // 播放/暂停按钮
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        playPauseButton.backgroundColor = .systemBlue
        playPauseButton.tintColor = .white
        playPauseButton.layer.cornerRadius = 32
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)

        // 上一首/下一首按钮
        previousButton.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        previousButton.tintColor = .label
        previousButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)

        nextButton.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        nextButton.tintColor = .label
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)

        // 播放模式按钮
        updateModeButton()
        modeButton.addTarget(self, action: #selector(modeButtonTapped), for: .touchUpInside)

        // 控制按钮堆栈
        controlsStackView.axis = .horizontal
        controlsStackView.alignment = .center
        controlsStackView.distribution = .fill
        controlsStackView.spacing = 32

        controlsStackView.addArrangedSubview(previousButton)
        controlsStackView.addArrangedSubview(playPauseButton)
        controlsStackView.addArrangedSubview(nextButton)
        controlsStackView.addArrangedSubview(modeButton)

        view.addSubview(controlsStackView)
    }

    private func setupTopControls() {
        // 收藏按钮
        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        favoriteButton.tintColor = isFavorite ? .systemRed : .label
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)

        // 缓存按钮
        cacheButton.setImage(UIImage(systemName: "arrow.down.circle"), for: .normal)
        cacheButton.setImage(UIImage(systemName: "arrow.down.circle.fill"), for: .selected)
        cacheButton.tintColor = isCached ? .systemBlue : .label
        cacheButton.addTarget(self, action: #selector(cacheButtonTapped), for: .touchUpInside)

        // 顶部按钮容器
        let topStackView = UIStackView()
        topStackView.axis = .horizontal
        topStackView.alignment = .leading
        topStackView.distribution = .fill
        topStackView.spacing = 16

        topStackView.addArrangedSubview(backButton)
        topStackView.addArrangedSubview(UIView()) // 弹性空间
        topStackView.addArrangedSubview(favoriteButton)
        topStackView.addArrangedSubview(cacheButton)

        view.addSubview(topStackView)

        // 设置约束
        backButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        cacheButton.translatesAutoresizingMaskIntoConstraints = false
        topStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),
            cacheButton.widthAnchor.constraint(equalToConstant: 44),
            cacheButton.heightAnchor.constraint(equalToConstant: 44),

            topStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            topStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            topStackView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupAudioNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterrupted),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    private func setupGradient() {
        gradientLayer.frame = view.bounds
    }

    // MARK: - Layout Methods

    private func layoutComponents() {
        let safeArea = view.safeAreaInsets
        let padding: CGFloat = 24
        let vinylSize: CGFloat = min(view.width - padding * 2, 320)

        // 黑胶唱片
        vinylRecordView.frame = CGRect(
            x: (view.width - vinylSize) / 2,
            y: safeArea.top + 100,
            width: vinylSize,
            height: vinylSize
        )

        // 曲目信息
        let infoY = vinylRecordView.maxY + 32
        trackInfoLabel.frame = CGRect(
            x: padding,
            y: infoY,
            width: view.width - padding * 2,
            height: 60
        )

        artistInfoLabel.frame = CGRect(
            x: padding,
            y: trackInfoLabel.maxY + 4,
            width: view.width - padding * 2,
            height: 24
        )

        // 进度控制
        let progressY = artistInfoLabel.maxY + 32
        currentTimeLabel.frame = CGRect(x: padding, y: progressY, width: 60, height: 20)
        durationLabel.frame = CGRect(x: view.width - padding - 60, y: progressY, width: 60, height: 20)

        progressSlider.frame = CGRect(
            x: currentTimeLabel.maxX + 16,
            y: progressY,
            width: durationLabel.minX - currentTimeLabel.maxX - 32,
            height: 20
        )

        // 播放控制
        let controlsY = progressSlider.maxY + 48
        let buttonSize: CGFloat = 64
        let playButtonSize: CGFloat = 80

        previousButton.frame = CGRect(x: (view.width - buttonSize * 3 - 32) / 2, y: controlsY, width: buttonSize, height: buttonSize)
        playPauseButton.frame = CGRect(x: previousButton.maxX + 16, y: controlsY - (playButtonSize - buttonSize) / 2, width: playButtonSize, height: playButtonSize)
        nextButton.frame = CGRect(x: playPauseButton.maxX + 16, y: controlsY, width: buttonSize, height: buttonSize)
        modeButton.frame = CGRect(x: nextButton.maxX + 8, y: controlsY + (buttonSize - 40) / 2, width: 40, height: 40)
    }

    // MARK: - Audio Setup

    private func setupAudioPlayer() {
        AudioPlayerManager.shared.delegate = self
        AudioPlayerManager.shared.setPlaylist(currentPlaylist, startIndex: currentIndex)
        AudioPlayerManager.shared.setPlaybackMode(playbackMode)
    }

    private func configureVinylView() {
        guard let track = currentTrack else { return }

        // 设置黑胶唱片图片
        vinylRecordView.setVinylImage(nil) // 使用默认黑胶纹理

        // 设置中心标签图片
        vinylRecordView.setCenterLabelImage(UIImage(systemName: "music.note"))

        // 初始化播放状态
        vinylRecordView.setPlaying(isPlaying)
    }

    private func updateTrackInfo() {
        guard let track = currentTrack else { return }

        trackInfoLabel.text = track.title
        artistInfoLabel.text = track.artist

        // 添加切换动画
        animateTrackInfoChange()
    }

    private func animateTrackInfoChange() {
        // 标题切换动画
        trackInfoLabel.alpha = 0
        artistInfoLabel.alpha = 0

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.trackInfoLabel.alpha = 1
            self.artistInfoLabel.alpha = 1
        }
    }

    private func updateModeButton() {
        let modeIcons: [PlaybackMode: String] = [
            .singleLoop: "repeat.1",
            .sequence: "repeat",
            .random: "shuffle"
        ]

        modeButton.setImage(UIImage(systemName: modeIcons[playbackMode] ?? "repeat.1"), for: .normal)
        modeButton.tintColor = playbackMode == .singleLoop ? .systemBlue : .label
    }

    private func updateProgressDisplay() {
        let currentTime = AudioPlayerManager.shared.currentTime
        let duration = AudioPlayerManager.shared.duration

        currentTimeLabel.text = formatTime(currentTime)
        durationLabel.text = formatTime(duration)

        if duration > 0 {
            progressSlider.value = Float(currentTime / duration)
        }
    }

    private func hideNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.isToolbarHidden = true
    }

    private func showNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Action Methods

    @objc private func backButtonTapped() {
        heavyFeedback.impactOccurred()
        dismiss(animated: true)
    }

    @objc private func playPauseButtonTapped() {
        mediumFeedback.impactOccurred()
        AudioPlayerManager.shared.playPause()
    }

    @objc private func previousButtonTapped() {
        mediumFeedback.impactOccurred()
        AudioPlayerManager.shared.previousTrack()
    }

    @objc private func nextButtonTapped() {
        mediumFeedback.impactOccurred()
        AudioPlayerManager.shared.nextTrack()
    }

    @objc private func modeButtonTapped() {
        lightFeedback.impactOccurred()

        // 切换播放模式
        switch playbackMode {
        case .singleLoop:
            playbackMode = .sequence
        case .sequence:
            playbackMode = .random
        case .random:
            playbackMode = .singleLoop
        }

        updateModeButton()
        AudioPlayerManager.shared.setPlaybackMode(playbackMode)

        // 添加切换动画
        animateModeChange()
    }

    @objc private func favoriteButtonTapped() {
        lightFeedback.impactOccurred()
        isFavorite.toggle()
        favoriteButton.isSelected = isFavorite
        favoriteButton.tintColor = isFavorite ? .systemRed : .label

        // 添加心形动画
        animateFavoriteButton()
    }

    @objc private func cacheButtonTapped() {
        lightFeedback.impactOccurred()
        isCached.toggle()
        cacheButton.isSelected = isCached
        cacheButton.tintColor = isCached ? .systemBlue : .label

        // 实现缓存逻辑
        if isCached {
            cacheCurrentTrack()
        } else {
            uncacheCurrentTrack()
        }
    }

    @objc private func progressSliderValueChanged() {
        let duration = AudioPlayerManager.shared.duration
        let seekTime = TimeInterval(progressSlider.value) * duration
        AudioPlayerManager.shared.seek(to: seekTime)

        // 添加滑动反馈
        lightFeedback.impactOccurred()
    }

    @objc private func audioSessionInterrupted() {
        pause()
    }

    @objc private func audioRouteChanged() {
        // 处理音频路由变化（如拔掉耳机）
        updateNowPlayingInfo()
    }

    // MARK: - Audio Control Methods

    private func play() {
        AudioPlayerManager.shared.play()
        vinylRecordView.setPlaying(true)
        playPauseButton.isSelected = true
        isPlaying = true

        updateNowPlayingInfo()
    }

    private func pause() {
        AudioPlayerManager.shared.pause()
        vinylRecordView.setPlaying(false)
        playPauseButton.isSelected = false
        isPlaying = false

        updateNowPlayingInfo()
    }

    private func nextTrack() {
        AudioPlayerManager.shared.nextTrack()
        vinylRecordView.animateVinylSwap()
    }

    private func previousTrack() {
        AudioPlayerManager.shared.previousTrack()
        vinylRecordView.animateVinylSwap()
    }

    private func seek(to time: TimeInterval) {
        AudioPlayerManager.shared.seek(to: time)
        updateProgressDisplay()
    }

    private func cacheCurrentTrack() {
        guard let track = currentTrack else { return }
        // 实现缓存逻辑
        print("Caching track: \(track.title)")
    }

    private func uncacheCurrentTrack() {
        guard let track = currentTrack else { return }
        // 实现取消缓存逻辑
        print("Uncaching track: \(track.title)")
    }

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else { return }

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = AudioPlayerManager.shared.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = AudioPlayerManager.shared.currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Animation Methods

    private func animateModeChange() {
        UIView.animate(withDuration: 0.2, animations: {
            self.modeButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.modeButton.transform = .identity
            }
        }
    }

    private func animateFavoriteButton() {
        if isFavorite {
            // 心形飘散效果
            let heartImageView = UIImageView(image: UIImage(systemName: "heart.fill"))
            heartImageView.tintColor = .systemRed
            heartImageView.frame = favoriteButton.bounds
            favoriteButton.addSubview(heartImageView)

            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) {
                heartImageView.transform = CGAffineTransform(translationX: 0, y: -50)
                heartImageView.alpha = 0
            } completion: { _ in
                heartImageView.removeFromSuperview()
            }
        }

        // 按钮缩放动画
        UIView.animate(withDuration: 0.1, animations: {
            self.favoriteButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.favoriteButton.transform = .identity
            }
        }
    }

    // MARK: - Utility Methods

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AudioPlayerManagerDelegate

extension PlayerViewController: AudioPlayerManagerDelegate {
    func audioPlayer(_ player: AudioPlayerManager, didChangeState state: PlaybackState) {
        DispatchQueue.main.async {
            switch state {
            case .playing:
                self.play()
            case .paused:
                self.pause()
            case .loading:
                // 显示加载状态
                break
            case .completed:
                // 处理播放完成
                break
            case .idle:
                // 处理空闲状态
                break
            }
        }
    }

    func audioPlayer(_ player: AudioPlayerManager, didUpdateCurrentTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateProgressDisplay()
        }
    }

    func audioPlayer(_ player: AudioPlayerManager, didUpdateDuration duration: TimeInterval) {
        DispatchQueue.main.async {
            self.durationLabel.text = self.formatTime(duration)
        }
    }

    func audioPlayer(_ player: AudioPlayerManager, didChangeTrack track: AudioTrack?) {
        DispatchQueue.main.async {
            self.currentTrack = track
            self.updateTrackInfo()
            self.configureVinylView()
        }
    }
}

// MARK: - VinylRecordViewDelegate

extension PlayerViewController: VinylRecordViewDelegate {
    func vinylRecordDidTapPlayPause(_ vinylView: VinylRecordView) {
        mediumFeedback.impactOccurred()
        AudioPlayerManager.shared.playPause()
    }

    func vinylRecordDidSwipe(_ vinylView: VinylRecordView, direction: UISwipeGestureRecognizer.Direction) {
        mediumFeedback.impactOccurred()

        switch direction {
        case .left:
            nextTrack()
        case .right:
            previousTrack()
        default:
            break
        }
    }

    func vinylRecordDidPan(_ vinylView: VinylRecordView, translation: CGPoint) {
        // 可以添加拖动调整进度的功能
        let progress = (translation.x + vinylView.frame.width / 2) / vinylView.frame.width
        let clampedProgress = max(0, min(1, progress))
        progressSlider.value = Float(clampedProgress)

        let duration = AudioPlayerManager.shared.duration
        let seekTime = TimeInterval(clampedProgress) * duration
        AudioPlayerManager.shared.seek(to: seekTime)
    }
}

// MARK: - UIImageView Extension for Blur Effect

extension UIImageView {
    func blur(radius: CGFloat) {
        let blurContext = CIContext(options: nil)
        guard let currentImage = self.image,
              let ciImage = CIImage(image: currentImage) else { return }

        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(radius, forKey: kCIInputRadiusKey)

        if let outputImage = blurFilter?.outputImage,
           let cgImage = blurContext.createCGImage(outputImage, from: ciImage.extent) {
            self.image = UIImage(cgImage: cgImage)
        }
    }
}

// MARK: - Custom Slider

class CustomSlider: UISlider {
    var trackHeight: CGFloat = 4 {
        didSet { setNeedsDisplay() }
    }

    var thumbSize: CGSize = CGSize(width: 20, height: 20) {
        didSet { setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        // 绘制轨道
        let trackRect = CGRect(
            x: thumbSize.width / 2,
            y: (rect.height - trackHeight) / 2,
            width: rect.width - thumbSize.width,
            height: trackHeight
        )

        // 最小轨道
        let minTrackPath = UIBezierPath(roundedRect: trackRect, cornerRadius: trackHeight / 2)
        minimumTrackTintColor?.setFill()
        minTrackPath.fill()

        // 最大轨道
        let maxTrackPath = UIBezierPath(roundedRect: trackRect, cornerRadius: trackHeight / 2)
        maximumTrackTintColor?.setFill()
        maxTrackPath.fill()
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let thumbCenter = CGPoint(
            x: rect.minX + CGFloat(value) * rect.width,
            y: rect.midY
        )

        return CGRect(
            x: thumbCenter.x - thumbSize.width / 2,
            y: thumbCenter.y - thumbSize.height / 2,
            width: thumbSize.width,
            height: thumbSize.height
        )
    }
}