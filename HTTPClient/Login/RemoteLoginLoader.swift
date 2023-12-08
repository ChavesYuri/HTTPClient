import Foundation

struct Credentials: Encodable {
    let username: String
    let password: String
}

public struct UserInfoModel: Equatable {
    let isPremium: Bool
    let token: String
    
    public init(isPremium: Bool, token: String) {
        self.isPremium = isPremium
        self.token = token
    }
}

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

final class RemoteLoginLoader {
    private let httpClient: HTTPClient
    
    enum Error: Swift.Error {
        case invalidData
        case connectivity
    }
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    typealias LoginResult = Swift.Result<UserInfoModel, RemoteLoginLoader.Error>
    
    func execute(credentials: Credentials, completion: @escaping (LoginResult) -> Void) {
        let request = LoginRequest(username: credentials.username, password: credentials.password)
        httpClient.performRequest(request: request.urlRequest) { result in
            switch result {
            case .failure:
                completion(.failure(.connectivity))
            case let .success((data, response)):
                guard let user = try? UserInfoMapper.map(data, response) else {
                    completion(.failure(.invalidData))
                    return
                }
                
                completion(.success(user))
            }
        }
    }
}


private class UserInfoMapper {
    private struct UserInfo: Decodable {
        let premium: Bool
        let token: String
        
        var userModel: UserInfoModel {
            return UserInfoModel(isPremium: premium, token: token)
        }
    }
    
    static var OK_200: Int { 200 }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> UserInfoModel {
        guard response.statusCode == OK_200 else {
            throw RemoteLoginLoader.Error.invalidData
        }
        
        let remoteUser = try JSONDecoder().decode(UserInfo.self, from: data)
        return remoteUser.userModel
    }
}
