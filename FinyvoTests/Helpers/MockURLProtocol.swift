//
//  MockURLProtocol.swift
//  FinyvoTests
//
//  Created by Moises Núñez on 02/12/26.
//  URLProtocol mock para pruebas de networking.
//

import Foundation

final class MockURLProtocol: URLProtocol {

    /// Handler que devuelve (data, response, error) para cada request
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Helpers

extension MockURLProtocol {

    /// Crea una URLSession configurada con este mock
    static func mockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    /// Configura respuesta exitosa con JSON
    static func setSuccessResponse(json: [String: Any], statusCode: Int = 200) {
        requestHandler = { request in
            let data = try JSONSerialization.data(withJSONObject: json)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }
    }

    /// Configura respuesta de error con envelope estándar
    static func setErrorResponse(statusCode: Int, code: String, message: String, requestId: String = "test-req-id") {
        requestHandler = { request in
            let errorBody: [String: Any] = [
                "error": [
                    "code": code,
                    "message": message,
                    "requestId": requestId
                ]
            ]
            let data = try JSONSerialization.data(withJSONObject: errorBody)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }
    }
}
