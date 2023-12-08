import XCTest
@testable import HTTPClient

final class RemoteLoginLoaderTests: XCTestCase {
    func test_init_doesNotRequestHTTPClient() {
        let (_, httpClient) = makeSUT()
        
        XCTAssertEqual(httpClient.count(), 0)
    }
    
    func test_execute_requestsHTTPClient() {
        let (sut, httpClient) = makeSUT()
        
        sut.execute(credentials: .init(username: "a username", password: "a password")) { _ in }
        
        XCTAssertEqual(httpClient.count(), 1)
    }
    
    func test_execute_givenCredentialAppendItInTheBody() {
        let (sut, httpClient) = makeSUT()
        let credentials = Credentials(username: "a username", password: "a password")
        
        sut.execute(credentials: credentials) { _ in }
        
        let expectedData = try? JSONSerialization.data(withJSONObject: ["username": credentials.username, "password": credentials.password])
        
        XCTAssertEqual(httpClient.request(at: 0)?.httpBody?.count, expectedData?.count)
    }
    
    func test_execute_whenFails_completesWithConnectivityError() {
        let (sut, httpClient) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.connectivity), when: {
            let anyError = NSError(domain: "a domain", code: 1)
            httpClient.complete(with: anyError, at: 0)
        })
    }
    
    func test_execute_whenSucceedsWithCodeDifferentFrom200_completesWithInvalidCodeError() {
        let (sut, httpClient) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let failedHTTPResponse = HTTPURLResponse(url: anyURL(), statusCode: 400, httpVersion: nil, headerFields: nil)!
            let anyData = Data("any data".utf8)
            httpClient.complete(with: anyData, response: failedHTTPResponse, at: 0)
        })
    }
    
    func test_execute_whenCodeIs200AndJSONIsNotValid() {
        let (sut, httpClient) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let failedHTTPResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
            let anyData = Data("invalid json".utf8)
            httpClient.complete(with: anyData, response: failedHTTPResponse, at: 0)
        })
    }
    
    func test_execute_whenCodeIs200AndValidJSON_completesWithSuccess() {
        let (sut, httpClient) = makeSUT()
        let expectedUserModel = UserInfoModel(isPremium: false, token: "a token")
        expect(sut, toCompleteWith: .success(expectedUserModel), when: {
            let failedHTTPResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
            let validJSON = makeValidJSON(expectedUserModel)
            httpClient.complete(with: validJSON, response: failedHTTPResponse, at: 0)
        })
    }
    
    // MARK: Helpers
    
    private func makeValidJSON(_ user: UserInfoModel) -> Data {
        let json: [String : Any] = ["premium": user.isPremium, "token": user.token]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(
        _ sut: RemoteLoginLoader,
        toCompleteWith result: RemoteLoginLoader.LoginResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var resultReceived: RemoteLoginLoader.LoginResult?
        sut.execute(credentials: .init(username: "a username", password: "a password")) { result in
            resultReceived = result
        }
        
        action()
        
        switch (resultReceived, result) {
        case let (.success(receivedModel), .success(expectedModel)):
            XCTAssertEqual(receivedModel, expectedModel)
        case let (.failure(receivedError), .failure(expectedError)):
            XCTAssertEqual(receivedError, expectedError)
        default:
            XCTFail("Expected result \(result) got \(String(describing: resultReceived))", file: file, line: line)
        }
    }
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (RemoteLoginLoader, HTTPClientSpy) {
        let httpClient = HTTPClientSpy()
        let sut = RemoteLoginLoader(httpClient: httpClient)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(httpClient, file: file, line: line)
        
        return (sut, httpClient)
    }
    
    private func anyURL() -> URL {
        URL(string: "https://a-url")!
    }
}
