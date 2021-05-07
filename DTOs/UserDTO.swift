//
//  File.swift
//
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public extension DTO {
    struct UserDTO: Identifiable, Codable {
        public let id: UUID
        public let organization: DTO.Organization?
        public let firstName: String
        public let lastName: String
        public let email: String
        public let isFoundingUser: Bool
    }
}
