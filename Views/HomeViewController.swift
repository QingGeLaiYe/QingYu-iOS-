//
//  HomeViewController.swift
//  QingYu
//
//  Created by QingYu Team on 2025-11-27.
//

import UIKit
import SwiftUI

// 场景模型
struct Scene {
    let id: String
    let title: String
    let titleKey: String
    let icon: String
    let backgroundColor: UIColor
    let tracks: [AudioTrack]
}

// 音频曲目单元格
class TrackCell: UITableViewCell {
    static let identifier = "TrackCell"

    private let coverImageView = UIImageView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let durationLabel = UILabel()
    private let cacheButton = UIButton(type: .custom)
    private let favoriteButton = UIButton(type: .custom)
    private let sceneTagLabel = UILabel()

    var onCacheButtonTapped: (() -> Void)?
    var onFavoriteButtonTapped: (() -> Void)?

    private var isCached: Bool = false
    private var isFavorite: Bool = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutComponents()
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        selectionStyle = .none

        // 封面图片
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 12
        coverImageView.backgroundColor = UIColor.systemGray6

        // 标题
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        // 艺术家
        artistLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        artistLabel.textColor = .secondaryLabel
        artistLabel.numberOfLines = 1

        // 时长
        durationLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        durationLabel.textColor = .secondaryLabel

        // 场景标签
        sceneTagLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        sceneTagLabel.textColor = .white
        sceneTagLabel.backgroundColor = UIColor.systemBlue
        sceneTagLabel.layer.cornerRadius = 8
        sceneTagLabel.clipsToBounds = true
        sceneTagLabel.textAlignment = .center

        // 缓存按钮
        cacheButton.setImage(UIImage(systemName: "arrow.down.circle"), for: .normal)
        cacheButton.setImage(UIImage(systemName: "arrow.down.circle.fill"), for: .selected)
        cacheButton.tintColor = .systemBlue
        cacheButton.contentMode = .scaleAspectFit

        // 收藏按钮
        favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        favoriteButton.tintColor = .systemRed
        favoriteButton.contentMode = .scaleAspectFit

        contentView.addSubview(coverImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(artistLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(sceneTagLabel)
        contentView.addSubview(cacheButton)
        contentView.addSubview(favoriteButton)
    }

    private func setupActions() {
        cacheButton.addTarget(self, action: #selector(cacheButtonTapped), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)

        // 添加按钮点击的触觉反馈
        cacheButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        favoriteButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
    }

    @objc private func buttonTouchDown() {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }

    @objc private func cacheButtonTapped() {
        isCached.toggle()
        cacheButton.isSelected = isCached
        onCacheButtonTapped?()
    }

    @objc private func favoriteButtonTapped() {
        isFavorite.toggle()
        favoriteButton.isSelected = isFavorite
        onFavoriteButtonTapped?()

        // 添加心形动画
        animateFavoriteButton()
    }

    private func layoutComponents() {
        let padding: CGFloat = 16
        let imageSize: CGFloat = 56
        let buttonSize: CGFloat = 32

        coverImageView.frame = CGRect(x: padding, y: padding, width: imageSize, height: imageSize)

        let labelX = coverImageView.maxX + 12
        let labelWidth = contentView.width - labelX - buttonSize * 2 - padding * 3

        titleLabel.frame = CGRect(x: labelX, y: coverImageView.y, width: labelWidth, height: 20)
        artistLabel.frame = CGRect(x: labelX, y: titleLabel.maxY + 2, width: labelWidth, height: 18)

        // 场景标签
        let tagWidth: CGFloat = 60
        let tagHeight: CGFloat = 16
        sceneTagLabel.frame = CGRect(x: labelX, y: artistLabel.maxY + 4, width: tagWidth, height: tagHeight)

        durationLabel.frame = CGRect(x: contentView.width - padding - 60, y: coverImageView.maxY - 16, width: 60, height: 16)

        // 按钮
        cacheButton.frame = CGRect(x: contentView.width - padding - buttonSize * 2, y: padding + (imageSize - buttonSize) / 2, width: buttonSize, height: buttonSize)
        favoriteButton.frame = CGRect(x: contentView.width - padding - buttonSize, y: padding + (imageSize - buttonSize) / 2, width: buttonSize, height: buttonSize)
    }

    private func animateFavoriteButton() {
        UIView.animate(withDuration: 0.1, animations: {
            self.favoriteButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.favoriteButton.transform = .identity
            }
        }

        if isFavorite {
            // 添加心形飘散效果
            let heartImageView = UIImageView(image: UIImage(systemName: "heart.fill"))
            heartImageView.tintColor = .systemRed
            heartImageView.frame = favoriteButton.bounds
            favoriteButton.addSubview(heartImageView)

            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) {
                heartImageView.transform = CGAffineTransform(translationX: 0, y: -30)
                heartImageView.alpha = 0
            } completion: { _ in
                heartImageView.removeFromSuperview()
            }
        }
    }

    func configure(with track: AudioTrack, isCached: Bool = false, isFavorite: Bool = false) {
        titleLabel.text = track.title
        artistLabel.text = track.artist
        durationLabel.text = formatDuration(track.duration)
        sceneTagLabel.text = track.sceneTags.first ?? Bundle.localizedString(forKey: "uncategorized")

        self.isCached = isCached
        self.isFavorite = isFavorite

        cacheButton.isSelected = isCached
        favoriteButton.isSelected = isFavorite

        // 设置封面图片（可以添加默认的黑胶唱片图标）
        if track.imageURL != nil {
            // 异步加载封面图片
            loadCoverImage(from: track.imageURL)
        } else {
            coverImageView.image = createDefaultCover()
        }

        // 设置场景标签颜色
        setSceneTagColor(for: track.sceneTags.first)
    }

    private func createDefaultCover() -> UIImage? {
        let size = CGSize(width: 56, height: 56)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemGray6.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // 绘制简单的黑胶唱片图标
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2 - 8

            // 外圈
            UIColor.black.setFill()
            let outerCircle = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
            outerCircle.fill()

            // 内圈
            UIColor.red.setFill()
            let innerRadius: CGFloat = 8
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

    private func setSceneTagColor(for sceneTag: String?) {
        let colorMap: [String: UIColor] = [
            Bundle.localizedString(forKey: "zen_meditation"): UIColor.systemTeal,
            Bundle.localizedString(forKey: "daily_relax"): UIColor.systemBlue,
            Bundle.localizedString(forKey: "sleep_aid"): UIColor.systemPurple,
            Bundle.localizedString(forKey: "anxiety_relief"): UIColor.systemGreen
        ]

        sceneTagLabel.backgroundColor = colorMap[sceneTag ?? ""] ?? UIColor.systemGray
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

class HomeViewController: UIViewController {

    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let searchController = UISearchController(searchResultsController: nil)
    private let sceneScrollView = UIScrollView()
    private let sceneStackView = UIStackView()
    private let tableView = UITableView()
    private let gradientLayer = CAGradientLayer()

    // MARK: - Properties
    private var scenes: [Scene] = []
    private var selectedScene: Scene?
    private var filteredTracks: [AudioTrack] = []
    private var isSearching: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
        setupNavigationBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutComponents()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup Methods

    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupGradient()
        setupTitle()
        setupSearchController()
        setupSceneScrollView()
        setupTableView()
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.systemBackground.withAlphaComponent(0.8).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupTitle() {
        titleLabel.text = "轻语"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label

        subtitleLabel.text = Bundle.localizedString(forKey: "subtitle_healing_sounds")
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = Bundle.localizedString(forKey: "search_placeholder")
        searchController.searchBar.searchTextField.backgroundColor = UIColor.systemGray6
        searchController.searchBar.searchTextField.layer.cornerRadius = 16

        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupSceneScrollView() {
        sceneScrollView.showsHorizontalScrollIndicator = false
        sceneScrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        sceneStackView.axis = .horizontal
        sceneStackView.spacing = 12
        sceneStackView.distribution = .fill

        sceneScrollView.addSubview(sceneStackView)
        view.addSubview(sceneScrollView)
    }

    private func setupTableView() {
        tableView.register(TrackCell.self, forCellReuseIdentifier: TrackCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false

        view.addSubview(tableView)
    }

    private func setupNavigationBar() {
        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(profileButtonTapped)
        )
        profileButton.tintColor = .label

        navigationItem.rightBarButtonItem = profileButton
    }

    private func setupData() {
        // 创建示例场景数据
        scenes = [
            Scene(
                id: "zen_meditation",
                title: Bundle.localizedString(forKey: "zen_meditation"),
                titleKey: "zen_meditation",
                icon: "leaf.circle.fill",
                backgroundColor: UIColor.systemTeal.withAlphaComponent(0.1),
                tracks: createZenMeditationTracks()
            ),
            Scene(
                id: "daily_relax",
                title: Bundle.localizedString(forKey: "daily_relax"),
                titleKey: "daily_relax",
                icon: "sun.max.circle.fill",
                backgroundColor: UIColor.systemBlue.withAlphaComponent(0.1),
                tracks: createDailyRelaxTracks()
            ),
            Scene(
                id: "sleep_aid",
                title: Bundle.localizedString(forKey: "sleep_aid"),
                titleKey: "sleep_aid",
                icon: "moon.circle.fill",
                backgroundColor: UIColor.systemPurple.withAlphaComponent(0.1),
                tracks: createSleepAidTracks()
            ),
            Scene(
                id: "anxiety_relief",
                title: Bundle.localizedString(forKey: "anxiety_relief"),
                titleKey: "anxiety_relief",
                icon: "heart.circle.fill",
                backgroundColor: UIColor.systemGreen.withAlphaComponent(0.1),
                tracks: createAnxietyReliefTracks()
            )
        ]

        // 默认选择第一个场景
        selectedScene = scenes.first
        filteredTracks = selectedScene?.tracks ?? []
        setupSceneButtons()
        tableView.reloadData()
    }

    private func setupSceneButtons() {
        sceneStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for scene in scenes {
            let button = createSceneButton(for: scene)
            sceneStackView.addArrangedSubview(button)
        }
    }

    private func createSceneButton(for scene: Scene) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = scenes.firstIndex(of: scene) ?? 0
        button.setTitle(scene.title, for: .normal)
        button.setImage(UIImage(systemName: scene.icon), for: .normal)
        button.tintColor = scene == selectedScene ? .systemBlue : .systemGray
        button.backgroundColor = scene == selectedScene ? scene.backgroundColor : .clear
        button.layer.cornerRadius = 16
        button.layer.borderWidth = scene == selectedScene ? 0 : 1
        button.layer.borderColor = UIColor.systemGray4.cgColor

        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)

        button.addTarget(self, action: #selector(sceneButtonTapped(_:)), for: .touchUpInside)

        // 添加触觉反馈
        button.addTarget(self, action: #selector(sceneButtonTouchDown), for: .touchDown)

        return button
    }

    @objc private func sceneButtonTouchDown() {
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
    }

    @objc private func sceneButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < scenes.count else { return }

        selectedScene = scenes[index]
        filteredTracks = selectedScene?.tracks ?? []

        // 更新按钮状态
        setupSceneButtons()

        // 平滑滚动到顶部
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)

        // 添加切换动画
        animateSceneTransition()
    }

    @objc private func profileButtonTapped() {
        let profileVC = ProfileViewController()
        let navigationController = UINavigationController(rootViewController: profileVC)
        present(navigationController, animated: true)
    }

    private func layoutComponents() {
        gradientLayer.frame = view.bounds

        let safeArea = view.safeAreaInsets
        let padding: CGFloat = 16

        // 标题
        titleLabel.frame = CGRect(
            x: padding,
            y: safeArea.top + 8,
            width: view.width - padding * 2,
            height: 35
        )

        subtitleLabel.frame = CGRect(
            x: padding,
            y: titleLabel.maxY + 4,
            width: view.width - padding * 2,
            height: 22
        )

        // 搜索栏
        let searchBarFrame = CGRect(
            x: padding,
            y: subtitleLabel.maxY + 12,
            width: view.width - padding * 2,
            height: 44
        )
        searchController.searchBar.frame = searchBarFrame

        // 场景滚动视图
        let sceneHeight: CGFloat = 48
        sceneScrollView.frame = CGRect(
            x: 0,
            y: searchBarFrame.maxY + 16,
            width: view.width,
            height: sceneHeight
        )

        sceneStackView.frame = CGRect(
            x: 16,
            y: 0,
            width: sceneScrollView.contentSize.width,
            height: sceneHeight
        )

        // 表格视图
        tableView.frame = CGRect(
            x: 0,
            y: sceneScrollView.maxY + 16,
            width: view.width,
            height: view.height - sceneScrollView.maxY - 16
        )
    }

    // MARK: - Animation Methods

    private func animateSceneTransition() {
        // 淡出效果
        UIView.animate(withDuration: 0.2, animations: {
            self.tableView.alpha = 0.3
        }) { _ in
            // 更新数据并淡入
            self.tableView.reloadData()
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.alpha = 1.0
            })
        }

        // 添加微妙的缩放效果
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.tableView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.tableView.transform = .identity
            }
        }
    }

    // MARK: - Data Creation Methods

    private func createZenMeditationTracks() -> [AudioTrack] {
        return [
            AudioTrack(
                id: "zen1",
                title: Bundle.localizedString(forKey: "track_bamboo_forest"),
                artist: Bundle.localizedString(forKey: "artist_qingyu"),
                duration: 30,
                audioURL: URL(string: "https://example.com/audio/zen1.mp3")!,
                imageURL: nil,
                sceneTags: [Bundle.localizedString(forKey: "zen_meditation")],
                isOffline: false,
                localPath: nil
            ),
            AudioTrack(
                id: "zen2",
                title: Bundle.localizedString(forKey: "track_mountain_stream"),
                artist: Bundle.localizedString(forKey: "artist_qingyu"),
                duration: 25,
                audioURL: URL(string: "https://example.com/audio/zen2.mp3")!,
                imageURL: nil,
                sceneTags: [Bundle.localizedString(forKey: "zen_meditation")],
                isOffline: false,
                localPath: nil
            )
        ]
    }

    private func createDailyRelaxTracks() -> [AudioTrack] {
        return [
            AudioTrack(
                id: "relax1",
                title: Bundle.localizedString(forKey: "track_morning_dew"),
                artist: Bundle.localizedString(forKey: "artist_qingyu"),
                duration: 20,
                audioURL: URL(string: "https://example.com/audio/relax1.mp3")!,
                imageURL: nil,
                sceneTags: [Bundle.localizedString(forKey: "daily_relax")],
                isOffline: false,
                localPath: nil
            )
        ]
    }

    private func createSleepAidTracks() -> [AudioTrack] {
        return [
            AudioTrack(
                id: "sleep1",
                title: Bundle.localizedString(forKey: "track_moonlight_lullaby"),
                artist: Bundle.localizedString(forKey: "artist_qingyu"),
                duration: 40,
                audioURL: URL(string: "https://example.com/audio/sleep1.mp3")!,
                imageURL: nil,
                sceneTags: [Bundle.localizedString(forKey: "sleep_aid")],
                isOffline: false,
                localPath: nil
            )
        ]
    }

    private func createAnxietyReliefTracks() -> [AudioTrack] {
        return [
            AudioTrack(
                id: "relief1",
                title: Bundle.localizedString(forKey: "track_gentle_rain"),
                artist: Bundle.localizedString(forKey: "artist_qingyu"),
                duration: 35,
                audioURL: URL(string: "https://example.com/audio/relief1.mp3")!,
                imageURL: nil,
                sceneTags: [Bundle.localizedString(forKey: "anxiety_relief")],
                isOffline: false,
                localPath: nil
            )
        ]
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTracks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackCell.identifier, for: indexPath) as? TrackCell else {
            return UITableViewCell()
        }

        let track = filteredTracks[indexPath.row]
        cell.configure(with: track, isCached: false, isFavorite: false)

        // 设置按钮回调
        cell.onCacheButtonTapped = {
            // 处理缓存逻辑
            self.handleCacheAction(for: track)
        }

        cell.onFavoriteButtonTapped = {
            // 处理收藏逻辑
            self.handleFavoriteAction(for: track)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let track = filteredTracks[indexPath.row]

        // 播放曲目
        let playerViewController = PlayerViewController()
        playerViewController.setTrack(track, playlist: filteredTracks, currentIndex: indexPath.row)

        let navigationController = UINavigationController(rootViewController: playerViewController)
        navigationController.modalPresentationStyle = .fullScreen

        present(navigationController, animated: true)

        // 添加点击反馈
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }

    // MARK: - Action Handlers

    private func handleCacheAction(for track: AudioTrack) {
        // 实现缓存逻辑
        print("Cache track: \(track.title)")
    }

    private func handleFavoriteAction(for track: AudioTrack) {
        // 实现收藏逻辑
        print("Favorite track: \(track.title)")
    }
}

// MARK: - UISearchResultsUpdating

extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            isSearching = false
            filteredTracks = selectedScene?.tracks ?? []
            tableView.reloadData()
            return
        }

        isSearching = true
        filteredTracks = (selectedScene?.tracks ?? []).filter { track in
            track.title.localizedCaseInsensitiveContains(searchText) ||
            track.artist.localizedCaseInsensitiveContains(searchText)
        }

        tableView.reloadData()
    }
}