//
//  ProfileViewController.swift
//  QingYu
//
//  Created by QingYu Team on 2025-11-27.
//

import UIKit

class ProfileViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let profileHeaderView = UIView()
    private let userImageView = UIImageView()
    private let userNameLabel = UILabel()
    private let userSubtitleLabel = UILabel()
    private let favoritesSection = UIView()
    private let settingsSection = UIView()
    private let aboutSection = UIView()

    // MARK: - Properties
    private var favoriteTracks: [AudioTrack] = []
    private var cachedTracks: [AudioTrack] = []
    private var totalCacheSize: Int64 = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutComponents()
    }

    // MARK: - Setup Methods

    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupScrollView()
        setupProfileHeader()
        setupFavoritesSection()
        setupSettingsSection()
        setupAboutSection()
    }

    private func setupNavigationBar() {
        title = Bundle.localizedString(forKey: "profile_title")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
    }

    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }

    private func setupProfileHeader() {
        // 用户头像（使用默认的国风图标）
        userImageView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        userImageView.tintColor = .systemBlue
        userImageView.contentMode = .center
        userImageView.layer.cornerRadius = 40
        userImageView.clipsToBounds = true
        userImageView.image = UIImage(systemName: "person.circle.fill")
        userImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 60, weight: .medium)

        // 用户名称（显示为轻语用户）
        userNameLabel.text = Bundle.localizedString(forKey: "qingyu_user")
        userNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        userNameLabel.textColor = .label

        // 用户副标题
        userSubtitleLabel.text = Bundle.localizedString(forKey: "enjoy_healing_journey")
        userSubtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        userSubtitleLabel.textColor = .secondaryLabel

        profileHeaderView.addSubview(userImageView)
        profileHeaderView.addSubview(userNameLabel)
        profileHeaderView.addSubview(userSubtitleLabel)

        contentView.addSubview(profileHeaderView)
    }

    private func setupFavoritesSection() {
        let sectionHeader = createSectionHeader(
            title: Bundle.localizedString(forKey: "my_favorites"),
            icon: "heart.fill",
            color: .systemRed
        )

        let favoritesCollectionView = createFavoritesCollectionView()
        let emptyStateView = createEmptyStateView(
            message: Bundle.localizedString(forKey: "no_favorites_yet"),
            icon: "heart",
            color: .systemRed
        )

        favoritesSection.addSubview(sectionHeader)
        favoritesSection.addSubview(favoritesCollectionView)
        favoritesSection.addSubview(emptyStateView)

        contentView.addSubview(favoritesSection)
    }

    private func setupSettingsSection() {
        let sectionHeader = createSectionHeader(
            title: Bundle.localizedString(forKey: "settings"),
            icon: "gearshape.fill",
            color: .systemBlue
        )

        let settingsStack = createSettingsStack()

        settingsSection.addSubview(sectionHeader)
        settingsSection.addSubview(settingsStack)

        contentView.addSubview(settingsSection)
    }

    private func setupAboutSection() {
        let sectionHeader = createSectionHeader(
            title: Bundle.localizedString(forKey: "about"),
            icon: "info.circle.fill",
            color: .systemGray
        )

        let aboutStack = createAboutStack()

        aboutSection.addSubview(sectionHeader)
        aboutSection.addSubview(aboutStack)

        contentView.addSubview(aboutSection)
    }

    // MARK: - Component Creation Methods

    private func createSectionHeader(title: String, icon: String, color: UIColor) -> UIView {
        let headerView = UIView()

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(iconImageView)
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44)
        ])

        return headerView
    }

    private func createFavoritesCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.itemSize = CGSize(width: 140, height: 180)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FavoriteTrackCell.self, forCellWithReuseIdentifier: "FavoriteTrackCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        return collectionView
    }

    private func createEmptyStateView(message: String, icon: String, color: UIColor) -> UIView {
        let emptyView = UIView()

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color.withAlphaComponent(0.5)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        emptyView.addSubview(iconImageView)
        emptyView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: emptyView.topAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            messageLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor, constant: -20)
        ])

        return emptyView
    }

    private func createSettingsStack() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 1
        stackView.backgroundColor = .systemGray5
        stackView.layer.cornerRadius = 12
        stackView.clipsToBounds = true

        // 后台播放设置
        let backgroundPlaybackRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "background_playback"),
            subtitle: Bundle.localizedString(forKey: "background_playback_desc"),
            type: .toggle,
            key: "background_playback_enabled"
        )

        // 锁屏控制
        let lockScreenControlRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "lock_screen_control"),
            subtitle: Bundle.localizedString(forKey: "lock_screen_control_desc"),
            type: .toggle,
            key: "lock_screen_control_enabled"
        )

        // 默认播放模式
        let playbackModeRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "default_playback_mode"),
            subtitle: Bundle.localizedString(forKey: "default_playback_mode_desc"),
            type: .selection,
            key: "default_playback_mode"
        )

        // 自动缓存
        let autoCacheRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "auto_cache"),
            subtitle: Bundle.localizedString(forKey: "auto_cache_desc"),
            type: .toggle,
            key: "auto_cache_enabled"
        )

        // 缓存管理
        let cacheManagementRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "cache_management"),
            subtitle: formatCacheSize(),
            type: .navigation,
            key: "cache_management"
        )

        [backgroundPlaybackRow, lockScreenControlRow, playbackModeRow, autoCacheRow, cacheManagementRow].forEach {
            stackView.addArrangedSubview($0)
        }

        return stackView
    }

    private func createAboutStack() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 1
        stackView.backgroundColor = .systemGray5
        stackView.layer.cornerRadius = 12
        stackView.clipsToBounds = true

        // 版本信息
        let versionRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "version"),
            subtitle: getAppVersion(),
            type: .info,
            key: "version"
        )

        // 隐私政策
        let privacyPolicyRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "privacy_policy"),
            subtitle: Bundle.localizedString(forKey: "privacy_policy_desc"),
            type: .navigation,
            key: "privacy_policy"
        )

        // 用户协议
        let userAgreementRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "user_agreement"),
            subtitle: Bundle.localizedString(forKey: "user_agreement_desc"),
            type: .navigation,
            key: "user_agreement"
        )

        // 评价应用
        let rateAppRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "rate_app"),
            subtitle: Bundle.localizedString(forKey: "rate_app_desc"),
            type: .navigation,
            key: "rate_app"
        )

        // 分享应用
        let shareAppRow = createSettingsRow(
            title: Bundle.localizedString(forKey: "share_app"),
            subtitle: Bundle.localizedString(forKey: "share_app_desc"),
            type: .navigation,
            key: "share_app"
        )

        [versionRow, privacyPolicyRow, userAgreementRow, rateAppRow, shareAppRow].forEach {
            stackView.addArrangedSubview($0)
        }

        return stackView
    }

    // MARK: - Settings Row Types

    enum SettingsRowType {
        case toggle
        case selection
        case navigation
        case info
    }

    private func createSettingsRow(title: String, subtitle: String, type: SettingsRowType, key: String) -> UIView {
        let rowView = UIView()
        rowView.backgroundColor = .systemBackground
        rowView.tag = key.hashValue

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        rowView.addSubview(stackView)

        switch type {
        case .toggle:
            let toggleSwitch = UISwitch()
            toggleSwitch.tag = key.hashValue
            toggleSwitch.addTarget(self, action: #selector(toggleSwitchChanged(_:)), for: .valueChanged)
            toggleSwitch.translatesAutoresizingMaskIntoConstraints = false

            // 设置初始状态
            let defaultValue = getDefaultValue(for: key)
            toggleSwitch.isOn = defaultValue

            rowView.addSubview(toggleSwitch)

            NSLayoutConstraint.activate([
                toggleSwitch.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -16),
                toggleSwitch.centerYAnchor.constraint(equalTo: rowView.centerYAnchor)
            ])

        case .navigation:
            let arrowImageView = UIImageView()
            arrowImageView.image = UIImage(systemName: "chevron.right")
            arrowImageView.tintColor = .systemGray3
            arrowImageView.contentMode = .scaleAspectFit
            arrowImageView.translatesAutoresizingMaskIntoConstraints = false

            rowView.addSubview(arrowImageView)

            NSLayoutConstraint.activate([
                arrowImageView.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -16),
                arrowImageView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                arrowImageView.widthAnchor.constraint(equalToConstant: 12),
                arrowImageView.heightAnchor.constraint(equalToConstant: 12)
            ])

        case .info:
            // 不需要额外控件
            break

        case .selection:
            let selectionLabel = UILabel()
            selectionLabel.text = getSelectedValue(for: key)
            selectionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            selectionLabel.textColor = .systemBlue
            selectionLabel.translatesAutoresizingMaskIntoConstraints = false

            rowView.addSubview(selectionLabel)

            NSLayoutConstraint.activate([
                selectionLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -16),
                selectionLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor)
            ])
        }

        // 添加手势识别
        if type != .toggle {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(settingsRowTapped(_:)))
            rowView.addGestureRecognizer(tapGesture)
        }

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 16),
            stackView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: rowView.trailingAnchor, constant: -60),
            rowView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])

        return rowView
    }

    // MARK: - Data Loading

    private func loadData() {
        loadFavoriteTracks()
        loadCachedTracks()
        updateCacheSize()
    }

    private func loadFavoriteTracks() {
        // 从 UserDefaults 加载收藏的曲目
        if let favoritesData = UserDefaults.standard.data(forKey: "favorite_tracks"),
           let favorites = try? JSONDecoder().decode([AudioTrack].self, from: favoritesData) {
            favoriteTracks = favorites
        }
    }

    private func loadCachedTracks() {
        // 从本地存储加载缓存的曲目
        if let cachedData = UserDefaults.standard.data(forKey: "cached_tracks"),
           let cached = try? JSONDecoder().decode([AudioTrack].self, from: cachedData) {
            cachedTracks = cached
        }
    }

    private func updateCacheSize() {
        // 计算缓存大小
        let cacheDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        totalCacheSize = calculateDirectorySize(cacheDirectory)
    }

    // MARK: - Layout Methods

    private func layoutComponents() {
        scrollView.frame = view.bounds

        let padding: CGFloat = 16
        var yOffset: CGFloat = 0

        // Profile Header
        profileHeaderView.frame = CGRect(x: 0, y: yOffset, width: view.width, height: 120)
        userImageView.frame = CGRect(x: (profileHeaderView.width - 80) / 2, y: 20, width: 80, height: 80)
        userNameLabel.frame = CGRect(x: padding, y: userImageView.maxY + 12, width: profileHeaderView.width - padding * 2, height: 28)
        userSubtitleLabel.frame = CGRect(x: padding, y: userNameLabel.maxY + 4, width: profileHeaderView.width - padding * 2, height: 20)

        yOffset = profileHeaderView.maxY + 32

        // Favorites Section
        favoritesSection.frame = CGRect(x: padding, y: yOffset, width: view.width - padding * 2, height: 240)

        // Settings Section
        yOffset = favoritesSection.maxY + 32
        settingsSection.frame = CGRect(x: padding, y: yOffset, width: view.width - padding * 2, height: 300)

        // About Section
        yOffset = settingsSection.maxY + 32
        aboutSection.frame = CGRect(x: padding, y: yOffset, width: view.width - padding * 2, height: 250)

        // Set content size
        yOffset = aboutSection.maxY
        contentView.frame = CGRect(x: 0, y: 0, width: view.width, height: yOffset)
        scrollView.contentSize = contentView.size
    }

    // MARK: - Action Methods

    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func toggleSwitchChanged(_ sender: UISwitch) {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        // 保存设置
        UserDefaults.standard.set(sender.isOn, forKey: "setting_\(sender.tag)")

        // 特殊处理某些设置
        if sender.tag == "auto_cache_enabled".hashValue {
            if sender.isOn {
                // 启用自动缓存
                enableAutoCache()
            } else {
                // 禁用自动缓存
                disableAutoCache()
            }
        }
    }

    @objc private func settingsRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let rowView = gesture.view else { return }

        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        // 根据不同的设置项执行不同的操作
        if rowView.tag == "cache_management".hashValue {
            showCacheManagement()
        } else if rowView.tag == "privacy_policy".hashValue {
            showPrivacyPolicy()
        } else if rowView.tag == "user_agreement".hashValue {
            showUserAgreement()
        } else if rowView.tag == "rate_app".hashValue {
            rateApp()
        } else if rowView.tag == "share_app".hashValue {
            shareApp()
        } else if rowView.tag == "default_playback_mode".hashValue {
            showPlaybackModeSelection()
        }
    }

    // MARK: - Utility Methods

    private func getDefaultValue(for key: String) -> Bool {
        switch key {
        case "background_playback_enabled":
            return UserDefaults.standard.object(forKey: "setting_\(key.hashValue)") as? Bool ?? true
        case "lock_screen_control_enabled":
            return UserDefaults.standard.object(forKey: "setting_\(key.hashValue)") as? Bool ?? true
        case "auto_cache_enabled":
            return UserDefaults.standard.object(forKey: "setting_\(key.hashValue)") as? Bool ?? false
        default:
            return false
        }
    }

    private func getSelectedValue(for key: String) -> String {
        if key == "default_playback_mode" {
            let mode = UserDefaults.standard.string(forKey: "setting_\(key.hashValue)") ?? "singleLoop"
            switch mode {
            case "singleLoop":
                return Bundle.localizedString(forKey: "single_loop")
            case "sequence":
                return Bundle.localizedString(forKey: "sequence_play")
            case "random":
                return Bundle.localizedString(forKey: "random_play")
            default:
                return Bundle.localizedString(forKey: "single_loop")
            }
        }
        return ""
    }

    private func formatCacheSize() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalCacheSize)
    }

    private func getAppVersion() -> String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return Bundle.localizedString(forKey: "version_unknown")
        }
        return "\(version) (\(build))"
    }

    private func calculateDirectorySize(_ directory: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                guard let isDirectory = resourceValues.isDirectory, !isDirectory,
                      let fileSize = resourceValues.fileSize else { continue }
                totalSize += Int64(fileSize)
            } catch {
                continue
            }
        }

        return totalSize
    }

    // MARK: - Specific Actions

    private func enableAutoCache() {
        // 实现自动缓存逻辑
        print("Auto cache enabled")
    }

    private func disableAutoCache() {
        // 实现禁用自动缓存逻辑
        print("Auto cache disabled")
    }

    private func showCacheManagement() {
        let alert = UIAlertController(
            title: Bundle.localizedString(forKey: "cache_management"),
            message: Bundle.localizedString(forKey: "cache_size_message") + formatCacheSize(),
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: Bundle.localizedString(forKey: "clear_cache"), style: .destructive) { _ in
            self.clearAllCache()
        })

        alert.addAction(UIAlertAction(title: Bundle.localizedString(forKey: "cancel"), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.width / 2, y: view.height / 2, width: 0, height: 0)
        }

        present(alert, animated: true)
    }

    private func clearAllCache() {
        // 实现清除所有缓存的逻辑
        print("Clear all cache")
        totalCacheSize = 0
        // 更新 UI
        if let settingsStack = settingsSection.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            for view in settingsStack.arrangedSubviews {
                if view.tag == "cache_management".hashValue {
                    if let subtitleLabel = view.subviews.first?.subviews.first(where: { $0 is UILabel && ($0 as? UILabel)?.font?.pointSize == 14 }) as? UILabel {
                        subtitleLabel.text = formatCacheSize()
                    }
                    break
                }
            }
        }
    }

    private func showPrivacyPolicy() {
        // 显示隐私政策
        print("Show privacy policy")
    }

    private func showUserAgreement() {
        // 显示用户协议
        print("Show user agreement")
    }

    private func rateApp() {
        // 打开应用商店评价页面
        print("Rate app")
    }

    private func shareApp() {
        let activityVC = UIActivityViewController(
            activityItems: [
                Bundle.localizedString(forKey: "share_app_message"),
                URL(string: "https://apps.apple.com/app/qingyu")!
            ],
            applicationActivities: nil
        )

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.width / 2, y: view.height / 2, width: 0, height: 0)
        }

        present(activityVC, animated: true)
    }

    private func showPlaybackModeSelection() {
        let alert = UIAlertController(
            title: Bundle.localizedString(forKey: "default_playback_mode"),
            message: Bundle.localizedString(forKey: "select_playback_mode"),
            preferredStyle: .actionSheet
        )

        let modes = [
            ("singleLoop", Bundle.localizedString(forKey: "single_loop")),
            ("sequence", Bundle.localizedString(forKey: "sequence_play")),
            ("random", Bundle.localizedString(forKey: "random_play"))
        ]

        for (key, title) in modes {
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                UserDefaults.standard.set(key, forKey: "setting_default_playback_mode".hashValue)
                // 更新 UI
                self.updatePlaybackModeSelection()
            })
        }

        alert.addAction(UIAlertAction(title: Bundle.localizedString(forKey: "cancel"), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.width / 2, y: view.height / 2, width: 0, height: 0)
        }

        present(alert, animated: true)
    }

    private func updatePlaybackModeSelection() {
        // 更新播放模式选择的 UI
        print("Update playback mode selection")
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate

extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favoriteTracks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteTrackCell", for: indexPath) as? FavoriteTrackCell else {
            return UICollectionViewCell()
        }

        let track = favoriteTracks[indexPath.item]
        cell.configure(with: track)
        cell.onTap = { [weak self] in
            self?.playFavoriteTrack(track)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let track = favoriteTracks[indexPath.item]
        playFavoriteTrack(track)

        // 添加点击反馈
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }

    private func playFavoriteTrack(_ track: AudioTrack) {
        // 播放收藏的曲目
        print("Play favorite track: \(track.title)")

        // 创建播放器并播放
        let playerVC = PlayerViewController()
        playerVC.setTrack(track, playlist: favoriteTracks, currentIndex: favoriteTracks.firstIndex(of: track) ?? 0)

        let navigationController = UINavigationController(rootViewController: playerVC)
        navigationController.modalPresentationStyle = .fullScreen

        present(navigationController, animated: true)
    }
}

// MARK: - Favorite Track Cell

class FavoriteTrackCell: UICollectionViewCell {
    static let identifier = "FavoriteTrackCell"

    private let coverImageView = UIImageView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let playOverlayView = UIView()
    private let playButton = UIImageView()

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupGesture()
    }

    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        // 封面图片
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.backgroundColor = .systemGray6

        // 标题
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        // 艺术家
        artistLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        artistLabel.textColor = .secondaryLabel
        artistLabel.numberOfLines = 1

        // 播放覆盖层
        playOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        playOverlayView.isHidden = true

        // 播放按钮
        playButton.image = UIImage(systemName: "play.circle.fill")
        playButton.tintColor = .white
        playButton.contentMode = .scaleAspectFit
        playOverlayView.addSubview(playButton)

        contentView.addSubview(coverImageView)
        contentView.addSubview(playOverlayView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(artistLabel)
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tapGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(cellLongPressed))
        contentView.addGestureRecognizer(longPressGesture)
    }

    @objc private func cellTapped() {
        onTap?()
    }

    @objc private func cellLongPressed(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // 添加长按效果
            UIView.animate(withDuration: 0.1) {
                self.contentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }

            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
        } else if gesture.state == .ended || gesture.state == .cancelled {
            UIView.animate(withDuration: 0.1) {
                self.contentView.transform = .identity
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let padding: CGFloat = 8

        // 封面图片
        coverImageView.frame = CGRect(x: 0, y: 0, width: contentView.width, height: contentView.height - 50)

        // 文本标签
        titleLabel.frame = CGRect(x: padding, y: coverImageView.maxY + 4, width: contentView.width - padding * 2, height: 36)
        artistLabel.frame = CGRect(x: padding, y: titleLabel.maxY + 2, width: contentView.width - padding * 2, height: 14)

        // 播放覆盖层
        playOverlayView.frame = coverImageView.bounds

        // 播放按钮
        let playButtonSize: CGFloat = 40
        playButton.frame = CGRect(
            x: (playOverlayView.width - playButtonSize) / 2,
            y: (playOverlayView.height - playButtonSize) / 2,
            width: playButtonSize,
            height: playButtonSize
        )
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        playOverlayView.isHidden = false
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.playOverlayView.isHidden = true
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.playOverlayView.isHidden = true
        }
    }

    func configure(with track: AudioTrack) {
        titleLabel.text = track.title
        artistLabel.text = track.artist

        // 设置封面图片
        if track.imageURL != nil {
            // 异步加载封面图片
            loadCoverImage(from: track.imageURL)
        } else {
            coverImageView.image = createDefaultCover()
        }
    }

    private func createDefaultCover() -> UIImage? {
        let size = CGSize(width: 140, height: 140)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemGray6.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // 绘制简单的黑胶唱片图标
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2 - 16

            // 外圈
            UIColor.black.setFill()
            let outerCircle = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            outerCircle.fill()

            // 内圈
            UIColor.red.setFill()
            let innerRadius: CGFloat = 12
            let innerCircle = UIBezierPath(arcCenter: center, radius: innerRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            innerCircle.fill()
        }
    }

    private func loadCoverImage(from url: URL?) {
        guard let url = url else { return }
        // 异步图片加载实现
        DispatchQueue.global(qos: .background).async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.coverImageView.image = image
                }
            }
        }
    }
}