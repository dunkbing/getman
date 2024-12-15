//
//  KeyValuePair.swift
//  getman
//
//  Created by Bùi Đặng Bình on 15/12/24.
//

import Foundation
import SwiftData

@Model
final class KeyValuePair: Identifiable {
    var id: UUID
    var key: String
    var value: String
    var isEnabled: Bool
    var isHidden: Bool

    init(
        id: UUID = UUID(),
        key: String,
        value: String,
        isEnabled: Bool = true,
        isHidden: Bool = false
    ) {
        self.id = id
        self.key = key
        self.value = value
        self.isEnabled = isEnabled
        self.isHidden = isHidden
    }
}
