//
//  File.swift
//  File
//
//  Created by Daniel Jilg on 17.08.21.
//

import Foundation

extension UUID {
    static var empty: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
}
