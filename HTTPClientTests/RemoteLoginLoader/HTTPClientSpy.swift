import Foundation

@testable import HTTPClient

final class HTTPClientSpy: HTTPClient {
    private var requests = [(request: URLRequest, completion: (HTTPClient.Result) -> Void)]()
    
    func performRequest(request: URLRequest, completion: @escaping (HTTPClient.Result) -> Void) {
        requests.append((request, completion))
    }
    
    func complete(with error: Error, at index: Int) {
        requests[index].completion(.failure(error))
    }
    
    func complete(with data: Data, response: HTTPURLResponse, at index: Int) {
        requests[index].completion(.success((data, response)))
    }
    
    func count() -> Int {
        requests.count
    }
    
    func request(at index: Int) -> URLRequest? {
        requests[index].request
    }
}
