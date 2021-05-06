//
//  File.swift
//  
//
//  Created by Daniel Jilg on 09.04.21.
//

import Foundation

public struct UserDTO: Identifiable, Codable {
    public let id: UUID
    public let organization: OrganizationDTO?
    public let firstName: String
    public let lastName: String
    public let email: String
    public let isFoundingUser: Bool
}
