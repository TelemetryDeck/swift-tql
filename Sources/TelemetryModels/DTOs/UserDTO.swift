//
//  File.swift
//  
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public struct UserDTO: Identifiable {
    public let id: UUID
    public let organization: Organization?
    public let firstName: String
    public let lastName: String
    public let email: String
    public let isFoundingUser: Bool
}

#if os(Linux)
extension UserDTO: Content {}
#else
extension UserDTO: Codable {}
#endif
