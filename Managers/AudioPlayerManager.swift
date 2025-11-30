//
//  AudioPlayerManager.swift
//  QingYu
//
//  Created by QingYu Team on 2025-11-27.
//

import AVFoundation
import UIKit

// 音频播放模式
enum PlaybackMode {
    case singleLoop     // 单曲循环
    case sequence       // 顺序播放
    case random         // 随机播放
}

// 音频播放状态
enum PlaybackState {
    case idle           // 空闲状态
    case loading        // 加载中
    case playing        // 播放中
    case paused         // 暂停
    case completed      // 播放完成
}

// 音频曲目模型
struct AudioTrack {
    let id: String
    let title: String
    let artist: String
    let duration: TimeInterval
    let audioURL: URL
    let imageURL: URL?
    let sceneTags: [String]
    let isOffline: Bool
    let localPath: String?
}

protocol AudioPlayerManagerDelegate: AnyObject {
    func audioPlayer(_ player: AudioPlayerManager, didChangeState state: PlaybackState)
    func audioPlayer(_ player: AudioPlayerManager, didUpdateCurrentTime time: TimeInterval)
    func audioPlayer(_ player: AudioPlayerManager, didUpdateDuration duration: TimeInterval)
    func audioPlayer(_ player: AudioPlayerManager, didChangeTrack track: AudioTrack?)
}

class AudioPlayerManager: NSObject {

    static let shared = AudioPlayerManager()

    // MARK: - Properties
    weak var delegate: AudioPlayerManagerDelegate?

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var playbackMode: PlaybackMode = .singleLoop
    private var currentPlaylist: [AudioTrack] = []
    private var currentIndex: Int = 0
    private var isLoopEnabled: Bool = true

    var currentState: PlaybackState = .idle {
        didSet {
            delegate?.audioPlayer(self, didChangeState: currentState)
        }
    }

    var currentTrack: AudioTrack? {
        guard currentIndex < currentPlaylist.count else { return nil }
        return currentPlaylist[currentIndex]
    }

    var currentTime: TimeInterval {
        return player?.currentItem?.currentTime().seconds ?? 0
    }

    var duration: TimeInterval {
        return player?.currentItem?.duration.seconds ?? 0
    }

    var isPlaying: Bool {
        return player?.rate != 0 && player?.error == nil
    }

    // MARK: - Initialization
    private override init() {
        super.init()
        setupRemoteControls()
        observeAudioSessionInterruptions()
    }

    deinit {
        removeTimeObserver()
        player?.pause()
    }

    // MARK: - Public Methods

    /// 设置播放列表
    func setPlaylist(_ tracks: [AudioTrack], startIndex index: Int = 0) {
        currentPlaylist = tracks
        currentIndex = min(index, tracks.count - 1)

        guard !tracks.isEmpty else {
            stop()
            return
        }

        loadTrack(at: currentIndex)
    }

    /// 播放指定曲目
    func playTrack(at index: Int) {
        guard index < currentPlaylist.count else { return }
        currentIndex = index
        loadTrack(at: index)
        play()
    }

    /// 播放/暂停
    func playPause() {
        switch currentState {
        case .idle, .paused, .completed:
            play()
        case .playing:
            pause()
        case .loading:
            break
        }
    }

    /// 上一首
    func previousTrack() {
        guard !currentPlaylist.isEmpty else { return }

        switch playbackMode {
        case .random:
            currentIndex = Int.random(in: 0..<currentPlaylist.count)
        default:
            currentIndex = max(0, currentIndex - 1)
        }

        loadTrack(at: currentIndex)
        play()

        // 提供黑胶唱片切换的触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    /// 下一首
    func nextTrack() {
        guard !currentPlaylist.isEmpty else { return }

        switch playbackMode {
        case .random:
            currentIndex = Int.random(in: 0..<currentPlaylist.count)
        case .sequence:
            currentIndex = (currentIndex + 1) % currentPlaylist.count
        case .singleLoop:
            // 单曲循环模式下，仍然播放同一首，但重新开始
            loadTrack(at: currentIndex)
        }

        loadTrack(at: currentIndex)
        play()

        // 提供黑胶唱片切换的触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    /// 跳转到指定时间
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        let time = CMTime(seconds: time, preferredTimescale: 1000)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// 设置播放模式
    func setPlaybackMode(_ mode: PlaybackMode) {
        playbackMode = mode
    }

    /// 停止播放
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        currentState = .idle
        delegate?.audioPlayer(self, didChangeTrack: nil)
    }

    // MARK: - Private Methods

    private func loadTrack(at index: Int) {
        guard index < currentPlaylist.count else { return }

        let track = currentPlaylist[index]
        currentState = .loading
        delegate?.audioPlayer(self, didChangeTrack: track)

        // 创建新的播放项
        let url: URL
        if track.isOffline, let localPath = track.localPath {
            url = URL(fileURLWithPath: localPath)
        } else {
            url = track.audioURL
        }

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        // 配置音频会话以支持无缝循环
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)

        // 移除旧的观察者
        removeTimeObserver()

        // 设置新的播放项
        self.playerItem = playerItem
        player?.replaceCurrentItem(with: playerItem)

        // 添加观察者
        addTimeObserver()
        observePlayerItem(playerItem)

        // 预加载音频
        player?.currentItem?.preload()
    }

    private func play() {
        guard let player = player else { return }

        // 配置音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
            return
        }

        player.play()
        currentState = .playing
        updateNowPlayingInfo()
    }

    private func pause() {
        player?.pause()
        currentState = .paused
        updateNowPlayingInfo()
    }

    private func addTimeObserver() {
        guard let player = player else { return }

        let interval = CMTime(seconds: 0.1, preferredTimescale: 1000)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let currentTime = time.seconds
            self.delegate?.audioPlayer(self, didUpdateCurrentTime: currentTime)

            // 检查播放是否结束（用于无缝循环）
            if currentTime >= self.duration - 0.1 && self.duration > 0 {
                self.handlePlaybackCompletion()
            }
        }
    }

    private func removeTimeObserver() {
        guard let timeObserver = timeObserver, let player = player else { return }
        player.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }

    private func observePlayerItem(_ item: AVPlayerItem) {
        item.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        item.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let status = change?[.newKey] as? Int {
                switch AVPlayerItem.Status(rawValue: status) {
                case .readyToPlay:
                    if currentState == .loading {
                        delegate?.audioPlayer(self, didUpdateDuration: duration)
                        play()
                    }
                case .failed:
                    currentState = .idle
                    print("Player item failed to load")
                case .unknown:
                    break
                case .none:
                    break
                }
            }
        } else if keyPath == "duration" {
            if let duration = change?[.newKey] as? CMTime {
                delegate?.audioPlayer(self, didUpdateDuration: duration.seconds)
            }
        }
    }

    private func handlePlaybackCompletion() {
        removeTimeObserver()

        switch playbackMode {
        case .singleLoop:
            // 无缝循环同一首
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.loadTrack(at: self.currentIndex)
            }
        case .sequence:
            if currentIndex < currentPlaylist.count - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.nextTrack()
                }
            } else {
                currentState = .completed
            }
        case .random:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.nextTrack()
            }
        }
    }

    // MARK: - Remote Controls (锁屏控制)

    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] event in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.nextTrack()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in
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

    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()

        if let track = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func observeAudioSessionInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: interruptionType) else {
            return
        }

        switch type {
        case .began:
            pause()
        case .ended:
            if let options = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
                play()
            }
        @unknown default:
            break
        }
    }
}

// MARK: - Bundle Extension for Localization
extension Bundle {
    private static var bundle: Bundle?

    static func setLanguage(_ language: String) {
        if let path = Bundle.main.path(forResource: language, ofType: "lproj") {
            bundle = Bundle(path: path)
        } else {
            bundle = Bundle.main
        }
    }

    static func localizedString(forKey key: String) -> String {
        return bundle?.localizedString(forKey: key, value: nil, table: nil) ?? Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
}