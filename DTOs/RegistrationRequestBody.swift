//
//  File.swift
//
//
//  Created by Daniel Jilg on 14.05.21.
//

import Foundation
public extension DTO {
    struct RegistrationRequestBody: Codable {
        public var registrationToken: String = ""
        public var organisationName: String = ""
        public var userFirstName: String = ""
        public var userLastName: String = ""
        public var userEmail: String = ""
        public var userPassword: String = ""
        public var userPasswordConfirm: String = ""
        public var receiveMarketingEmails: Bool

        public var isValid: Bool {
            !organisationName.isEmpty && !userFirstName.isEmpty && !userEmail.isEmpty && !userPassword.isEmpty && !userPasswordConfirm.isEmpty && !userPassword.contains(":")
        }
    }
}

#if canImport(Vapor)
import Vapor

extension DTO.RegistrationRequestBody: Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("userFirstName", as: String.self, is: !.empty)
        validations.add("userEmail", as: String.self, is: .email)
        validations.add("userPassword", as: String.self, is: .count(8...))
    }

    func makeOrganisation() -> Organization {
        Organization(name: organisationName)
    }

    func makeUser(organizationID: UUID) -> User {
        let hashedPassword = User.hash(from: userPassword)

        return User(
            firstName: userFirstName,
            lastName: userLastName,
            isFoundingUser: true,
            email: userEmail,
            receiveMarketingEmails: receiveMarketingEmails,
            passwordHash: hashedPassword,
            organizationID: organizationID
        )
    }
}
#endif
