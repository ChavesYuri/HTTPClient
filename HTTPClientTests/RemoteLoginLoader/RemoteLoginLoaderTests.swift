import XCTest
@testable import HTTPClient

struct Credentials: Encodable {
    let username: String
    let password: String
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
    
    enum Error {
        case invalidCode
        case connectivity
    }
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func execute(credentials: Credentials) {
        let request = LoginRequest(username: credentials.username, password: credentials.password)
        httpClient.performRequest(request: request.urlRequest) { _ in }
    }
}

final class RemoteLoginLoaderTests: XCTestCase {
    func test_init_doesNotRequestHTTPClient() {
        let httpClient = HTTPClientSpy()
        _ = RemoteLoginLoader(httpClient: httpClient)
        
        XCTAssertTrue(httpClient.requests.isEmpty)
    }
    
    func test_execute_requestsHTTPClient() {
        let httpClient = HTTPClientSpy()
        let sut = RemoteLoginLoader(httpClient: httpClient)
        
        sut.execute(credentials: .init(username: "a username", password: "a password"))
        
        XCTAssertFalse(httpClient.requests.isEmpty)
    }
    
    func test_execute_givenCredentialAppendItInTheBody() {
        let httpClient = HTTPClientSpy()
        let sut = RemoteLoginLoader(httpClient: httpClient)
        let credentials = Credentials(username: "a username", password: "a password")
        
        sut.execute(credentials: credentials)
        
        let expectedData = try? JSONSerialization.data(withJSONObject: ["username": credentials.username, "password": credentials.password])
        
        XCTAssertEqual(httpClient.requests.first?.key.httpBody?.count, expectedData?.count)
    }
    
    final class HTTPClientSpy: HTTPClient {
        var requests: [URLRequest: (HTTPClient.Result) -> Void] = [:]
        
        func performRequest(request: URLRequest, completion: @escaping (HTTPClient.Result) -> Void) {
            requests[request] = completion
        }
        
        func complete(at request: URLRequest, with error: Error) {
            requests[request]?(.failure(error))
        }
    }
}
