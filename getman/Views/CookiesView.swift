//
//  CookiesView.swift
//  getman
//
//  Created by Bùi Đặng Bình on 26/12/24.
//

import SwiftUI

struct HTTPCookie: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let value: String
    let domain: String?
    let path: String?
    let expiresDate: Date?
    let isSecure: Bool
    let isHTTPOnly: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Create a dedicated CookiesView
struct CookiesView: View {
    let cookies: [HTTPCookie]

    init(responseHeaders: [String: String]?) {
        // Parse cookies from response headers
        var parsedCookies: [HTTPCookie] = []

        if let setCookieHeaders = responseHeaders?["Set-Cookie"]?.components(separatedBy: ",") {
            for cookieString in setCookieHeaders {
                let components = cookieString.components(separatedBy: ";").map {
                    $0.trimmingCharacters(in: .whitespaces)
                }

                if let mainPart = components.first {
                    let nameValue = mainPart.components(separatedBy: "=")
                    if nameValue.count >= 2 {
                        let name = nameValue[0]
                        let value = nameValue[1]

                        var domain: String?
                        var path: String?
                        var expiresDate: Date?
                        var isSecure = false
                        var isHTTPOnly = false

                        // Parse cookie attributes
                        for attribute in components.dropFirst() {
                            let parts = attribute.components(separatedBy: "=")
                            let key = parts[0].lowercased()

                            switch key {
                            case "domain":
                                domain = parts.count > 1 ? parts[1] : nil
                            case "path":
                                path = parts.count > 1 ? parts[1] : nil
                            case "max-age":
                                if parts.count > 1, let maxAge = Double(parts[1]) {
                                    expiresDate = Date().addingTimeInterval(maxAge)
                                }
                            case "secure":
                                isSecure = true
                            case "httponly":
                                isHTTPOnly = true
                            default:
                                break
                            }
                        }

                        parsedCookies.append(
                            HTTPCookie(
                                name: name,
                                value: value,
                                domain: domain,
                                path: path,
                                expiresDate: expiresDate,
                                isSecure: isSecure,
                                isHTTPOnly: isHTTPOnly
                            ))
                    }
                }
            }
        }

        self.cookies = parsedCookies
    }

    var body: some View {
        ScrollView {
            if cookies.isEmpty {
                VStack {
                    Image(systemName: "cookie")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                    Text("No Cookies")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(cookies) { cookie in
                        CookieItemView(cookie: cookie)
                    }
                }
                .padding()
            }
        }
    }
}

// Create a view for individual cookie items
struct CookieItemView: View {
    let cookie: HTTPCookie
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm:ss"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cookie.name)
                    .font(.system(.headline, design: .monospaced))
                Spacer()
                Text(cookie.value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                if let domain = cookie.domain {
                    GridRow {
                        Text("Domain")
                            .foregroundColor(.secondary)
                        Text(domain)
                    }
                }

                if let path = cookie.path {
                    GridRow {
                        Text("Path")
                            .foregroundColor(.secondary)
                        Text(path)
                    }
                }

                if let expires = cookie.expiresDate {
                    GridRow {
                        Text("Expires")
                            .foregroundColor(.secondary)
                        Text(expires, formatter: dateFormatter)
                    }
                }

                GridRow {
                    Text("Flags")
                        .foregroundColor(.secondary)
                    HStack {
                        if cookie.isSecure {
                            Label("Secure", systemImage: "lock.fill")
                                .foregroundColor(.green)
                        }
                        if cookie.isHTTPOnly {
                            Label("HTTP Only", systemImage: "network")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}
