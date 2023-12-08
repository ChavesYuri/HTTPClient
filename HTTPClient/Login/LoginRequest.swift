import Foundation

struct LoginRequest: HTTPRequest {
    let username: String
    let password: String
    
    var path: String {
        "/path"
    }
    
    var method: AFHTTPMethod {
        .get
    }
    
    var parameters: [String : Any]? {
        [
            "username": username,
            "password": password
        ]
    }
}
