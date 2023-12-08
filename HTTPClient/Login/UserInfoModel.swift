import Foundation

public struct UserInfoModel: Equatable {
    let isPremium: Bool
    let token: String
    
    public init(isPremium: Bool, token: String) {
        self.isPremium = isPremium
        self.token = token
    }
}

struct Credentials: Encodable {
    let username: String
    let password: String
}
