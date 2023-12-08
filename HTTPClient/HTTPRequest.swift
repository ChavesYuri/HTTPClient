import Foundation

let mainHost = "google.com"
let mainScheme = "https"

enum AFHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

protocol HTTPRequest {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var method: AFHTTPMethod { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String] { get }
    var urlRequest: URLRequest { get }
}

extension HTTPRequest {
    var scheme: String { mainScheme }
    var host: String { mainHost }
    var parameters: [String: Any]? { nil }
    var headers: [String: String] { [:] }
    var urlRequest: URLRequest { DefaultURLRquestBuilder.build(request: self) }
}

final class DefaultURLRquestBuilder {
    static func build(request: HTTPRequest) -> URLRequest {
        var component = URLComponents()
        component.scheme = request.scheme
        component.host = request.host
        component.path = request.path
        guard let url = component.url else {
            fatalError("could not generate URL")
        }
        
        var urlRquest = URLRequest(url: url)
        urlRquest.httpBody = makeBody(from: request.parameters)
        urlRquest.httpMethod = request.method.rawValue
        urlRquest.allHTTPHeaderFields = makeHeaders(from: request.headers)
        
        return urlRquest
    }
    
    static func makeHeaders(from headers: [String: String]) -> [String: String] {
        var items = ["Content-Type": "application/json"]
        headers.forEach { key, value in
            items[key] = value
        }
        
        return items
    }
    
    static func makeBody(from parameters: [String: Any]?) -> Data? {
        if let parameters = parameters {
            return try? JSONSerialization.data(withJSONObject: parameters)
        }
        
        return nil
    }
}
