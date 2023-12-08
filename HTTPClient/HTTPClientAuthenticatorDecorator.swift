import Foundation

final class HTTPClientAuthenticatorDecorator: HTTPClient {
    private let decoratee: HTTPClient
    private let token: String
    
    init(decoratee: HTTPClient, token: String) {
        self.decoratee = decoratee
        self.token = token
    }
    
    func perfomRequest(request: URLRequest, completion: @escaping (HTTPClient.Result) -> Void) {
        decoratee.perfomRequest(request: makeAuthorizedRequest(from: request), completion: completion)
    }
    
    private func makeAuthorizedRequest(from request: URLRequest) -> URLRequest {
        var newRequest = request
        var items = request.allHTTPHeaderFields ?? [:]
        items["Authorization"] = "Bearer \(token)"
        newRequest.allHTTPHeaderFields = items
        
        return newRequest
    }
}
