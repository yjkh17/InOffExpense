import SwiftData
import Foundation

@Model
class User {
    var email: String
    var password: String  // For demonstration only!

    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}
