import XCTest

@testable import HTTPClient

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.registerStubProtocol()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.unregisterStubProtocol()
    }
    
    func test_performRequest_performRequestWithGivenURLRequest() {
        var request = anyURLReuquest()
        request.httpMethod = "POST"
        request.httpBody = Data()
        
        let exp = expectation(description: "wait for completion")
        
        URLProtocolStub.observeRequests { urlRequest in
            XCTAssertEqual(request, urlRequest)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.httpBody, Data())
            exp.fulfill()
        }
        
        makeSUT().performRequest(request: request) { _ in }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_perfomRequest_whenFails_completesWithError() {
        let anyError = NSError(domain: "any error", code: 1)
        let receivedError = resultErrorFor(data: nil, response: nil, error: anyError)
        
        XCTAssertEqual((receivedError as NSError?)?.domain, anyError.domain)
        XCTAssertEqual((receivedError as NSError?)?.code, anyError.code)
    }
    
    func test_perfomRequest_failsOnAllInvalidRepresentations() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_performRequest_whenGetDataAndHTTPURLResponse_completesWithSuccess() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        let result = resultValuesFor(data: data, response: response, error: nil)
        
        XCTAssertEqual(result?.data, data)
        XCTAssertEqual(result?.response.url, response.url)
        XCTAssertEqual(result?.response.statusCode, response.statusCode)
    }
    
    func test_performRequest_withNilData_completesWithSuccessAndEmptyData() {
        let response = anyHTTPURLResponse()
        let result = resultValuesFor(data: nil, response: anyHTTPURLResponse(), error: nil)
        
        XCTAssertEqual(result?.data, Data())
        XCTAssertEqual(result?.response.url, response.url)
        XCTAssertEqual(result?.response.statusCode, response.statusCode)
    }
    
    // MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func anyURLReuquest() -> URLRequest {
        let url = URL(string: "https://a-url")!
        return URLRequest(url: url)
    }
    
    private func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Error? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure and got \(result) instead", file: file, line: line)
            return nil
        }
        
    }
    
    private func resultValuesFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case let .success((data, response)):
            return (data, response)
        default:
            XCTFail("Expected success and got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HTTPClient.Result {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        
        var receivedResult: HTTPClient.Result!
        sut.performRequest(request: anyURLReuquest()) { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    func anyNSError() -> NSError {
        NSError(domain: "", code: -1)
    }
    
    func anyData() -> Data {
        Data("any data".utf8)
    }

    func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURLReuquest().url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURLReuquest().url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
}
