import XCTest

@testable import HTTPClient

final class HTTPClientAuthenticatorDecoratorTests: XCTestCase {
    func test_performRequest_withoutHeaders_addsAuthorization() {
        let decoratee = HTTPClientSpy()
        let token = "any token"
        let request = URLRequest(url: .init(string: "http://a-url")!)
        let sut = HTTPClientAuthenticatorDecorator(decoratee: decoratee, token: token)
        
        sut.performRequest(request: request) { _ in }
        
        XCTAssertEqual(decoratee.count(), 1)
        XCTAssertEqual(decoratee.request(at: 0)?.allHTTPHeaderFields?["Authorization"], "Bearer \(token)")
    }
    
    func test_performRequest_withHeaders_addsAuthorization() {
        let decoratee = HTTPClientSpy()
        let token = "any token"
        var request = URLRequest(url: .init(string: "http://a-url")!)
        request.allHTTPHeaderFields = ["a key header": "a value header"]
        let sut = HTTPClientAuthenticatorDecorator(decoratee: decoratee, token: token)
        
        sut.performRequest(request: request) { _ in }
        
        XCTAssertEqual(decoratee.request(at: 0)?.allHTTPHeaderFields?["Authorization"], "Bearer \(token)")
        XCTAssertEqual(decoratee.request(at: 0)?.allHTTPHeaderFields?["a key header"], "a value header")
    }
    
    final class HTTPClientSpy: HTTPClient {
        private var requests: [URLRequest] = []
        
        func performRequest(request: URLRequest, completion: @escaping (HTTPClient.Result) -> Void) {
            requests.append(request)
        }
        
        func count() -> Int {
            requests.count
        }
        
        func request(at index: Int) -> URLRequest? {
            requests[index]
        }
    }
}
