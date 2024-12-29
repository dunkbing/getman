//
//  HTTPHeader.swift
//  getman
//
//  Created by Bùi Đặng Bình on 29/12/24.
//

import Foundation

class HTTPHeadersProvider {
    static let shared = HTTPHeadersProvider()

    let commonHeaders: [String] = [
        "Accept",
        "Accept-Charset",
        "Accept-Encoding",
        "Accept-Language",
        "Authorization",
        "Cache-Control",
        "Connection",
        "Content-Length",
        "Content-Type",
        "Cookie",
        "Date",
        "Expect",
        "Host",
        "If-Match",
        "If-Modified-Since",
        "If-None-Match",
        "Origin",
        "Pragma",
        "Referer",
        "User-Agent",
        "X-Forwarded-For",
        "X-Requested-With",
    ]

    func filteredHeaders(searchText: String) -> [String] {
        if searchText.isEmpty {
            return commonHeaders
        }
        return commonHeaders.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}
