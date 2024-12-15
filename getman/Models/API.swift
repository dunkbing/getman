//
//  APIRequest.swift
//  getman
//
//  Created by Bùi Đặng Bình on 30/11/24.
//

import Foundation
import SwiftData
import SwiftUI

enum HTTPMethod: String, Codable, CaseIterable {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
    case OPTIONS
    case QUERY
    case HEAD

    var color: Color {
        switch self {
        case .GET: return .green
        case .POST: return .orange.opacity(0.9)
        case .PUT: return .blue
        case .DELETE: return .red.opacity(0.9)
        case .PATCH: return .purple
        case .HEAD: return .green
        case .OPTIONS: return .pink
        default: return .gray
        }
    }
}

@Model
final class APIRequest: Identifiable {
    var id: UUID
    var name: String
    var url: String
    private var methodRawValue: String
    private var bodyTypeRawValue: String
    var headersKvPairs: [KeyValuePair]
    var paramsKvPairs: [KeyValuePair]
    var formKvPairs: [KeyValuePair]
    var bodyContent: String
    var lastModified: Date

    var method: HTTPMethod {
        get {
            HTTPMethod(rawValue: methodRawValue) ?? .GET
        }
        set {
            methodRawValue = newValue.rawValue
        }
    }

    var bodyType: BodyType {
        get {
            BodyType(rawValue: bodyTypeRawValue) ?? .noBody
        }
        set {
            bodyTypeRawValue = newValue.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        name: String = "New Request",
        url: String = "",
        method: HTTPMethod = .GET,
        headersKvPairs: [KeyValuePair] = APIRequest.defaultHeaders,
        paramsKvPairs: [KeyValuePair] = [KeyValuePair(key: "", value: "")],
        formKvPairs: [KeyValuePair] = [KeyValuePair(key: "", value: "")],
        bodyType: BodyType = .noBody,
        bodyContent: String = "",
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.methodRawValue = method.rawValue
        self.bodyTypeRawValue = bodyType.rawValue
        self.headersKvPairs = headersKvPairs
        self.paramsKvPairs = paramsKvPairs
        self.formKvPairs = formKvPairs
        self.bodyContent = bodyContent
        self.lastModified = lastModified
    }

    static var defaultHeaders: [KeyValuePair] = [
        KeyValuePair(key: "Cache-Control", value: "no-cache", isHidden: true),
        KeyValuePair(key: "User-Agent", value: "Getman/1.0", isHidden: true),
        KeyValuePair(key: "Accept", value: "*/*", isHidden: true),
        KeyValuePair(key: "Accept-Encoding", value: "gzip, deflate, br", isHidden: true),
        KeyValuePair(key: "Connection", value: "keep-alive", isHidden: true),
        KeyValuePair(key: "", value: ""),
    ]

    static func new() -> APIRequest {
        APIRequest()
    }
}

struct APIResponse {
    var statusCode: Int
    var headers: [String: String]
    var data: Data?
    var error: Error?
}
