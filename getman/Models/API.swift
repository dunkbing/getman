//
//  APIRequest.swift
//  getman
//
//  Created by Bùi Đặng Bình on 30/11/24.
//

import Foundation
import SwiftUI

enum HTTPMethod: String, CaseIterable {
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

class APIRequest: Identifiable, Equatable {
    static func == (lhs: APIRequest, rhs: APIRequest) -> Bool {
        lhs.id == rhs.id
    }

    var method: HTTPMethod
    var name: String
    var url: String
    let id: UUID

    init(method: HTTPMethod, url: String, name: String) {
        self.method = method
        self.url = url
        self.name = name
        id = UUID()
    }

    static func new() -> APIRequest {
        APIRequest(method: .GET, url: "", name: "New HTTP Request")
    }
}

struct APIResponse {
    var statusCode: Int
    var headers: [String: String]
    var data: Data?
    var error: Error?
}
