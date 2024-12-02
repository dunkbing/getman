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
        case .POST: return .orange
        case .PUT: return .blue
        case .DELETE: return .red
        case .PATCH: return .purple
        default: return .gray
        }
    }
}

struct APIRequest: Identifiable, Hashable {
    let id = UUID()
    var method: HTTPMethod
    var url: String
    var name: String

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
