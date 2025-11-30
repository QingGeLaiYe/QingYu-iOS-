//
//  APIManager.swift
//  QingYu
//
//  Created by QingYu Team on 2025-11-27.
//

import Foundation
import Combine

// API响应基础结构
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let code: String?
    let data: T?
}

// 用户模型
struct User: Codable {
    let id: String
    let appleUserId: String
    let preferences: UserPreferences
    let favorites: [FavoriteAudio]
    let cachedAudios: [CachedAudio]
    let totalPlayTime: Int
    let totalSessions: Int
    let isPremium: Bool
    let favoriteCount: Int?
    let cachedCount: Int?
    let totalCacheSize: Int?
}

struct UserPreferences: Codable {
    let language: String
    let playbackMode: String
    let autoCache: Bool
    let backgroundPlayback: Bool
    let lockScreenControl: Bool
    let audioQuality: String
    let cacheStorageLimit: Int
}

struct FavoriteAudio: Codable {
    let audioId: String
    let addedAt: String
}

struct CachedAudio: Codable {
    let audioId: String
    let cachedAt: String
    let fileSize: Int
    let quality: String
}

// 音频模型（与后端对应）
struct APIAudioTrack: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let artist: String
    let duration: Int
    let coverImage: String?
    let scenes: String
    let instruments: [String]
    let natureSounds: [String]
    let moods: [String]?
    let tempo: Int?
    let key: String?
    let isPremium: Bool
    let isFeatured: Bool
    let playStats: PlayStats?
    let favoriteCount: Int
    let cacheCount: Int
    let createdAt: String
    let publishedAt: String?
    let audioUrls: AudioURLs
    let isFavorite: Bool?
    let isCached: Bool?
}

struct PlayStats: Codable {
    let totalPlays: Int
    let uniquePlayers: Int
    let averagePlayTime: Int
    let completionRate: Int
    let lastPlayedAt: String?
}

struct AudioURLs: Codable {
    let standard: String
    let high: String
}

// 场景模型
struct Scene: Codable {
    let id: String
    let name: String
    let count: Int
    let translations: [String: String]
}

// API请求管理器
class APIManager: ObservableObject {
    static let shared = APIManager()

    private let baseURL: String
    private let apiVersion: String
    private var authToken: String?
    private var cancellables = Set<AnyCancellable>()

    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var error: APIError?

    private init() {
        // 配置基础URL
        #if DEBUG
        self.baseURL = "http://localhost:3000"
        #else
        self.baseURL = "https://api.qingyu.app"
        #endif

        self.apiVersion = "/api/v1"

        // 从本地加载token
        loadAuthToken()
    }

    // MARK: - 网络请求基础方法

    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) -> AnyPublisher<APIResponse<T>, APIError> {

        isLoading = true
        error = nil

        let url = URL(string: "\(baseURL)\(apiVersion)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 添加认证token
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 添加设备信息
        addDeviceHeaders(to: &request)

        // 添加自定义headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // 添加请求体
        if let body = body {
            request.httpBody = body
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: APIResponse<T>.self, decoder: JSONDecoder())
            .map { response in
                self.isLoading = false

                if response.success {
                    return response
                } else {
                    throw APIError.serverError(response.message ?? "Unknown error", response.code)
                }
            }
            .mapError { error in
                self.isLoading = false

                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - 设备信息

    private func addDeviceHeaders(to request: inout URLRequest) {
        let deviceId = UIDevice.current.identifierForVendor ?? UUID().uuidString
        let deviceModel = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        request.setValue(deviceId.uuidString, forHTTPHeaderField: "X-Device-ID")
        request.setValue(deviceModel, forHTTPHeaderField: "X-Device-Model")
        request.setValue(osVersion, forHTTPHeaderField: "X-OS-Version")
        request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
    }

    // MARK: - 认证管理

    private func loadAuthToken() {
        authToken = UserDefaults.standard.string(forKey: "authToken")
    }

    private func saveAuthToken(_ token: String) {
        authToken = token
        UserDefaults.standard.set(token, forKey: "authToken")
    }

    private func removeAuthToken() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
    }

    // MARK: - 用户认证 API

    func authenticateWithAppleUserId(_ appleUserId: String, deviceInfo: [String: Any]? = nil, preferences: UserPreferences? = nil) -> AnyPublisher<APIResponse<User>, APIError> {

        let requestBody: [String: Any] = [
            "appleUserId": appleUserId
        ]

        if let deviceInfo = deviceInfo {
            requestBody["deviceInfo"] = deviceInfo
        }

        if let preferences = preferences {
            requestBody["preferences"] = preferences
        }

        return request<APIResponse<User>>(
            endpoint: "/users/auth/login",
            method: .POST,
            body: try? JSONSerialization.data(withJSONObject: requestBody)
        )
        .map { response in
            if let user = response.data {
                self.currentUser = user
                if let token = response.data?.id { // 这里实际应该是token字段
                    self.saveAuthToken(String(describing: token))
                }
            }
            return response
        }
        .eraseToAnyPublisher()
    }

    func getUserProfile() -> AnyPublisher<APIResponse<User>, APIError> {
        return request<APIResponse<User>>(endpoint: "/users/profile")
            .map { response in
                if let user = response.data {
                    self.currentUser = user
                }
                return response
            }
            .eraseToAnyPublisher()
    }

    func updatePreferences(_ preferences: UserPreferences) -> AnyPublisher<APIResponse<UserPreferences>, APIError> {
        let requestBody = ["preferences": preferences]

        return request<APIResponse<UserPreferences>>(
            endpoint: "/users/preferences",
            method: .PUT,
            body: try? JSONSerialization.data(withJSONObject: requestBody)
        )
        .eraseToAnyPublisher()
    }

    // MARK: - 收藏管理 API

    func addToFavorites(audioId: String) -> AnyPublisher<APIResponse<[String: Any]>, APIError> {
        let requestBody = ["audioId": audioId]

        return request<APIResponse<[String: Any]>>(
            endpoint: "/users/favorites",
            method: .POST,
            body: try? JSONSerialization.data(withJSONObject: requestBody)
        )
        .eraseToAnyPublisher()
    }

    func removeFromFavorites(audioId: String) -> AnyPublisher<APIResponse<[String: Any]>, APIError> {
        let requestBody = ["audioId": audioId]

        return request<APIResponse<[String: Any]>>(
            endpoint: "/users/favorites",
            method: .DELETE,
            body: try? JSONSerialization.data(withJSONObject: requestBody)
        )
        .eraseToAnyPublisher()
    }

    func getFavorites(page: Int = 1, limit: Int = 20) -> AnyPublisher<APIResponse<FavoritesResponse>, APIError> {
        let endpoint = "/users/favorites?page=\(page)&limit=\(limit)"
        return request<APIResponse<FavoritesResponse>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    // MARK: - 音频管理 API

    func getAudioList(
        page: Int = 1,
        limit: Int = 20,
        scene: String? = nil,
        language: String = "zh-Hans",
        instruments: [String]? = nil,
        natureSounds: [String]? = nil,
        search: String? = nil
    ) -> AnyPublisher<APIResponse<AudioListResponse>, APIError> {

        var endpoint = "/audio?page=\(page)&limit=\(limit)&language=\(language)"

        if let scene = scene {
            endpoint += "&scene=\(scene.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))"
        }

        if let instruments = instruments {
            let instrumentsString = instruments.joined(separator: ",")
            endpoint += "&instruments=\(instrumentsString)"
        }

        if let natureSounds = natureSounds {
            let soundsString = natureSounds.joined(separator: ",")
            endpoint += "&natureSounds=\(soundsString)"
        }

        if let search = search {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))"
        }

        return request<APIResponse<AudioListResponse>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    func getAudioByScene(scene: String, page: Int = 1, limit: Int = 20, language: String = "zh-Hans") -> AnyPublisher<APIResponse<SceneAudioResponse>, APIError> {
        let encodedScene = scene.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? scene
        let endpoint = "/audio/scene/\(encodedScene)?page=\(page)&limit=\(limit)&language=\(language)"

        return request<APIResponse<SceneAudioResponse>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    func searchAudio(query: String, language: String = "zh-Hans", page: Int = 1, limit: Int = 20) -> AnyPublisher<APIResponse<SearchResponse>, APIError> {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoint = "/audio/search?q=\(encodedQuery)&language=\(language)&page=\(page)&limit=\(limit)"

        return request<APIResponse<SearchResponse>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    func getAudioDetail(audioId: String, language: String = "zh-Hans") -> AnyPublisher<APIResponse<APIAudioTrack>, APIError> {
        let endpoint = "/audio/\(audioId)?language=\(language)"
        return request<APIResponse<APIAudioTrack>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    func getDownloadUrl(audioId: String, quality: String = "standard") -> AnyPublisher<APIResponse<DownloadResponse>, APIError> {
        let endpoint = "/audio/\(audioId)/download?quality=\(quality)&action=cache"
        return request<APIResponse<DownloadResponse>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    func getPopularAudio(period: String = "30d", language: String = "zh-Hans", limit: Int = 20) -> AnyPublisher<APIResponse<PopularResponse>, APIError> {
        let endpoint = "/audio/popular?period=\(period)&language=\(language)&limit=\(limit)"
        return request<APIResponse<PopularResponse>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    func getRecommendedAudio(basedOn: String? = nil, language: String = "zh-Hans", limit: Int = 20) -> AnyPublisher<APIResponse<RecommendedResponse>, APIError> {
        var endpoint = "/audio/recommended?language=\(language)&limit=\(limit)"

        if let basedOn = basedOn {
            endpoint += "&basedOn=\(basedOn)"
        }

        return request<APIResponse<RecommendedResponse>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    func getScenes(language: String = "zh-Hans") -> AnyPublisher<APIResponse<ScenesResponse>, APIError> {
        let endpoint = "/audio/scenes?language=\(language)"
        return request<APIResponse<ScenesResponse>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    func getInstruments(language: String = "zh-Hans") -> AnyPublisher<APIResponse<InstrumentsResponse>, APIError> {
        let endpoint = "/audio/instruments?language=\(language)"
        return request<APIResponse<InstrumentsResponse>>(endpoint: endpoint)
            .eraseToAnyPublisher()
    }

    // MARK: - 播放统计 API

    func recordPlayStats(audioId: String, duration: Int, completed: Bool = false) -> AnyPublisher<APIResponse<[String: Any]>, APIError> {
        let requestBody: [String: Any] = [
            "audioId": audioId,
            "duration": duration,
            "completed": completed,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        return request<APIResponse<[String: Any]>>(
            endpoint: "/audio/\(audioId)/stats",
            method: .POST,
            body: try? JSONSerialization.data(withJSONObject: requestBody)
        )
        .eraseToAnyPublisher()
    }

    // MARK: - 用户登出

    func logout() -> AnyPublisher<APIResponse<[String: Any]>, APIError> {
        return request<APIResponse<[String: Any]>>(endpoint: "/users/logout", method: .POST)
            .handleEvents(receiveOutput: { _ in
                self.removeAuthToken()
                self.currentUser = nil
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - 响应模型

struct AudioListResponse: Codable {
    let audios: [APIAudioTrack]
    let pagination: PaginationInfo
}

struct FavoritesResponse: Codable {
    let favorites: [APIAudioTrack]
    let pagination: PaginationInfo
}

struct SceneAudioResponse: Codable {
    let scene: String
    let audios: [APIAudioTrack]
    let pagination: PaginationInfo
}

struct SearchResponse: Codable {
    let query: String
    let audios: [APIAudioTrack]
    let pagination: PaginationInfo
}

struct PopularResponse: Codable {
    let period: String
    let audios: [APIAudioTrack]
}

struct RecommendedResponse: Codable {
    let basedOn: String
    let audios: [APIAudioTrack]
}

struct ScenesResponse: Codable {
    let scenes: [Scene]
}

struct InstrumentsResponse: Codable {
    let instruments: [Instrument]
}

struct Instrument: Codable {
    let id: String
    let name: String
    let count: Int
    let translations: [String: String]
}

struct PaginationInfo: Codable {
    let currentPage: Int
    let total: Int
    let totalPages: Int
    let limit: Int
}

struct DownloadResponse: Codable {
    let downloadUrl: String
    let quality: String
    let fileSize: Int
    let expiresAt: String
}

// MARK: - 错误类型

enum APIError: Error, LocalizedError {
    case networkError(String)
    case serverError(String, String?)
    case authenticationError(String)
    case notFound(String)
    case rateLimitExceeded(String)
    case invalidResponse(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return NSLocalizedString("Network Error: \(message)", comment: "")
        case .serverError(let message, _):
            return NSLocalizedString("Server Error: \(message)", comment: "")
        case .authenticationError(let message):
            return NSLocalizedString("Authentication Error: \(message)", comment: "")
        case .notFound(let message):
            return NSLocalizedString("Not Found: \(message)", comment: "")
        case .rateLimitExceeded(let message):
            return NSLocalizedString("Rate Limit Exceeded: \(message)", comment: "")
        case .invalidResponse(let message):
            return NSLocalizedString("Invalid Response: \(message)", comment: "")
        case .decodingError(let message):
            return NSLocalizedString("Decoding Error: \(message)", comment: "")
        }
    }
}

// MARK: - HTTP方法

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - 数据转换扩展

extension APIAudioTrack {
    func toAudioTrack() -> AudioTrack {
        return AudioTrack(
            id: self.id,
            title: self.title,
            artist: self.artist,
            duration: TimeInterval(self.duration),
            audioURL: URL(string: self.audioUrls.standard)!,
            imageURL: self.coverImage != nil ? URL(string: self.coverImage!) : nil,
            sceneTags: [self.scenes],
            isOffline: self.isCached ?? false,
            localPath: self.isCached == true ? "\(self.id).mp3" : nil
        )
    }
}

extension UserPreferences {
    func toPlaybackMode() -> PlaybackMode {
        switch self.playbackMode {
        case "singleLoop":
            return .singleLoop
        case "sequence":
            return .sequence
        case "random":
            return .random
        default:
            return .singleLoop
        }
    }

    func toLanguage() -> String {
        return self.language == "auto" ? Locale.current.languageCode ?? "zh-Hans" : self.language
    }
}