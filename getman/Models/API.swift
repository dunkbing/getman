//
//  APIRequest.swift
//  getman
//
//  Created by Bùi Đặng Bình on 30/11/24.
//

import Foundation

struct APIRequest: Identifiable, Hashable {
    let id = UUID()
    var method: String
    var url: String
    var name: String

    static func new() -> APIRequest {
        APIRequest(method: "GET", url: "", name: "New HTTP Request")
    }
}

struct APIResponse {
    var statusCode: Int
    var headers: [String: String]
    var data: Data?
    var error: Error?
}
