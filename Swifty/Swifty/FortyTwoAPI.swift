//
//  FortyTwoAPI.swift
//  Swifty
//

import Foundation

enum FortyTwoConfig {
    private static let environment = DotEnvLoader.load()

    nonisolated static let clientID = environment["CLIENT_ID"] ?? ""
    nonisolated static let clientSecret = environment["CLIENT_SECRET"] ?? ""
    nonisolated static let baseURL = URL(string: "https://api.intra.42.fr")!
}

enum DotEnvLoader {
    static func load() -> [String: String] {
        guard let url = dotEnvURL(),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }

        var values: [String: String] = [:]

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !line.isEmpty, !line.hasPrefix("#") else {
                continue
            }

            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else {
                continue
            }

            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))

            values[key] = value
        }

        return values
    }

    private static func dotEnvURL() -> URL? {
        if let bundleURL = Bundle.main.resourceURL?.appendingPathComponent(".env"),
           FileManager.default.fileExists(atPath: bundleURL.path) {
            return bundleURL
        }

        let fallbackURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".env")
        if FileManager.default.fileExists(atPath: fallbackURL.path) {
            return fallbackURL
        }

        return nil
    }
}

enum FortyTwoAPIError: LocalizedError {
    case missingCredentials
    case invalidURL
    case invalidResponse
    case loginNotFound
    case unauthorized
    case networkError
    case decodingError
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Add CLIENT_ID and CLIENT_SECRET to your local .env file before searching."
        case .invalidURL:
            return "The API URL is invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .loginNotFound:
            return "Login not found. Check the 42 login and try again."
        case .unauthorized:
            return "Authorization failed. Verify your UID and secret key."
        case .networkError:
            return "Network error. Check your connection and try again."
        case .decodingError:
            return "The app could not read the profile data returned by the API."
        case .serverError(let statusCode):
            return "The API returned an error with status code \(statusCode)."
        }
    }

    static func from(_ error: Error) -> FortyTwoAPIError {
        if let error = error as? FortyTwoAPIError {
            return error
        }

        if error is DecodingError {
            return .decodingError
        }

        return .networkError
    }
}

actor FortyTwoAPIClient {
    static let shared = FortyTwoAPIClient()

    private var cachedToken: String?
    private var tokenExpirationDate: Date?

// User infos 
    func fetchUser(login: String) async throws -> FortyTwoUser {
        let token = try await validAccessToken()
        let encodedLogin = login.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)

        guard let encodedLogin,
              let url = URL(string: "/v2/users/\(encodedLogin)", relativeTo: FortyTwoConfig.baseURL) else {
            throw FortyTwoAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await perform(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FortyTwoAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(FortyTwoUser.self, from: data)
            } catch {
                debugPrint("FortyTwoUser decoding failed:", decodingFailureDescription(for: error))
                throw FortyTwoAPIError.decodingError
            }
        case 401:
            cachedToken = nil
            tokenExpirationDate = nil
            throw FortyTwoAPIError.unauthorized
        case 404:
            throw FortyTwoAPIError.loginNotFound
        default:
            throw FortyTwoAPIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
// User Projects ! TODO
    
    

    private func validAccessToken() async throws -> String {
        if let cachedToken,
           let tokenExpirationDate,
           tokenExpirationDate > Date() {
            return cachedToken
        }

        guard !FortyTwoConfig.clientID.isEmpty, !FortyTwoConfig.clientSecret.isEmpty else {
            throw FortyTwoAPIError.missingCredentials
        }

        guard let url = URL(string: "/oauth/token", relativeTo: FortyTwoConfig.baseURL) else {
            throw FortyTwoAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type=client_credentials",
            "client_id=\(FortyTwoConfig.clientID)",
            "client_secret=\(FortyTwoConfig.clientSecret)"
        ]
        .joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await perform(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FortyTwoAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw FortyTwoAPIError.unauthorized
            }
            throw FortyTwoAPIError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let tokenResponse = try decoder.decode(FortyTwoTokenResponse.self, from: data)
            cachedToken = tokenResponse.accessToken
            tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn - 60))
            return tokenResponse.accessToken
        } catch {
            throw FortyTwoAPIError.decodingError
        }
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw FortyTwoAPIError.networkError
        }
    }

    private func decodingFailureDescription(for error: Error) -> String {
        switch error {
        case let DecodingError.keyNotFound(key, context):
            return "keyNotFound(\(key.stringValue)) at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        case let DecodingError.valueNotFound(type, context):
            return "valueNotFound(\(type)) at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        case let DecodingError.typeMismatch(type, context):
            return "typeMismatch(\(type)) at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        case let DecodingError.dataCorrupted(context):
            return "dataCorrupted at \(codingPathDescription(context.codingPath)): \(context.debugDescription)"
        default:
            return error.localizedDescription
        }
    }

    private func codingPathDescription(_ path: [CodingKey]) -> String {
        guard !path.isEmpty else { return "<root>" }
        return path.map(\.stringValue).joined(separator: ".")
    }
}

nonisolated struct FortyTwoTokenResponse: Decodable {
    let accessToken: String
    let expiresIn: Int
}

nonisolated struct FortyTwoUser: Decodable {
    let login: String
    let email: String?
    let phone: String?
    let displayname: String?
    let location: String?
    let wallet: Int?
    let achievements: [FortyTwoAchievement]
    let image: FortyTwoImage?
    let cursusUsers: [FortyTwoCursusUser]
    let projectsUsers: [FortyTwoProjectUser]

    var displayName: String {
        if let displayname, !displayname.isEmpty {
            return displayname
        }
        return login
    }

    var imageURL: String? {
        image?.versions?.medium ?? image?.link
    }
}

nonisolated struct FortyTwoAchievement: Decodable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let tier: String?
    let kind: String?
    let visible: Bool?
    let image: String?
}

nonisolated struct FortyTwoImage: Decodable {
    let link: String?
    let versions: FortyTwoImageVersions?
}

nonisolated struct FortyTwoImageVersions: Decodable {
    let large: String?
    let medium: String?
    let small: String?
    let micro: String?
}

nonisolated struct FortyTwoCursusUser: Decodable {
    let endAt: String?
    let level: Double?
    let skills: [FortyTwoSkill]
}

nonisolated struct FortyTwoSkill: Decodable, Identifiable {
    let id = UUID()
    let name: String
    let level: Double

    enum CodingKeys: String, CodingKey {
        case name
        case level
    }
}


// PROJECTS STRUCTS
nonisolated struct FortyTwoProjectUser: Decodable, Identifiable {
    let id: Int
    let finalMark: Int?
    let status: String?
    let validated: Bool?
    let project: FortyTwoProject
    let currentTeamID: Int?
    let cursusIDs: [Int]?
    let marked: Bool?
    let markedAt: String?
    let occurrence: Int?
    let retriableAt: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case finalMark
        case status
        case validated = "validated?"
        case project
        case currentTeamID
        case cursusIDs
        case marked
        case markedAt
        case occurrence
        case retriableAt
        case createdAt
        case updatedAt
    }

    var finalMarkText: String {
        if let finalMark {
            return "\(finalMark)"
        }
        return "No mark"
    }
}

nonisolated struct FortyTwoProject: Decodable {
    let id: Int
    let name: String
    let slug: String?
    let difficulty: Int?
    let description: String?
    let parent: FortyTwoProjectParent?
    let children: [FortyTwoProjectChild]?
    let objectives: [String]?
    let attachments: [FortyTwoProjectAttachment]?
    let createdAt: String?
    let updatedAt: String?
    let exam: Bool?
    let cursus: [FortyTwoProjectCursus]?
    let campus: [FortyTwoProjectCampus]?
    let skills: [FortyTwoProjectSkill]?
    let videos: [FortyTwoProjectVideo]?
    let tags: [FortyTwoProjectTag]?
    let projectSessions: [FortyTwoProjectSession]?
}
nonisolated struct FortyTwoProjectParent: Decodable {
    let id: Int
    let name: String?
    let slug: String?
    let url: String?
}

nonisolated struct FortyTwoProjectChild: Decodable, Identifiable {
    let id: Int
    let name: String?
    let slug: String?
    let url: String?
}

nonisolated struct FortyTwoProjectAttachment: Decodable {
}

nonisolated struct FortyTwoProjectCursus: Decodable, Identifiable {
    let id: Int
    let createdAt: String?
    let name: String?
    let slug: String?
}

nonisolated struct FortyTwoProjectCampus: Decodable, Identifiable {
    let id: Int
    let name: String?
    let timeZone: String?
    let language: FortyTwoProjectLanguage?
    let usersCount: Int?
    let vogsphereID: Int?
}

nonisolated struct FortyTwoProjectLanguage: Decodable, Identifiable {
    let id: Int
    let name: String?
    let identifier: String?
    let createdAt: String?
    let updatedAt: String?
}

nonisolated struct FortyTwoProjectSkill: Decodable, Identifiable {
    let id: Int
    let name: String?
    let createdAt: String?
}

nonisolated struct FortyTwoProjectVideo: Decodable {
}

nonisolated struct FortyTwoProjectTag: Decodable, Identifiable {
    let id: Int
    let name: String?
    let kind: String?
}

nonisolated struct FortyTwoProjectSession: Decodable, Identifiable {
    let id: Int
    let solo: Bool?
    let beginAt: String?
    let endAt: String?
    let difficulty: Int?
    let estimateTime: Int?
    let durationDays: Int?
    let terminatingAfter: Int?
    let projectID: Int?
    let campusID: Int?
    let cursusID: Int?
    let createdAt: String?
    let updatedAt: String?
    let maxPeople: Int?
    let isSubscriptable: Bool?
    let scales: [FortyTwoProjectScale]
    let uploads: [FortyTwoProjectUpload]
    let teamBehaviour: String?
}

nonisolated struct FortyTwoProjectScale: Decodable, Identifiable {
    let id: Int
    let correctionNumber: Int?
    let isPrimary: Bool?
}

nonisolated struct FortyTwoProjectUpload: Decodable, Identifiable {
    let id: Int
    let name: String?
}

