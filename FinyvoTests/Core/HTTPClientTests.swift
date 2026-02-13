//
//  HTTPClientTests.swift
//  FinyvoTests
//
//  Created by Moises Núñez on 02/12/26.
//  Tests para HTTPClient: éxito, errores, decodificación, auth header.
//

import XCTest
@testable import Finyvo

final class HTTPClientTests: XCTestCase {

    private var client: HTTPClient!

    override func setUp() {
        super.setUp()
        let session = MockURLProtocol.mockSession()
        client = HTTPClient(
            session: session,
            baseURL: URL(string: "https://test.finyvo.com")!,
            tokenProvider: { "test-token-123" },
            retryPolicy: RetryPolicy(maxAttempts: 1) // Sin reintentos para tests rápidos
        )
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        client = nil
        super.tearDown()
    }

    // MARK: - Success

    func testSuccessfulRequest() async throws {
        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "rates": ["EUR": 0.92, "DOP": 59.1]
        ])

        struct TestResponse: Decodable {
            let base: String
            let rates: [String: Double]
        }

        let endpoint = await HTTPEndpoint(path: "/fx/latest", requiresAuth: true)
        let response: TestResponse = try await client.send(endpoint, as: TestResponse.self)

        XCTAssertEqual(response.base, "USD")
        XCTAssertEqual(response.rates["EUR"], 0.92)
        XCTAssertEqual(response.rates["DOP"], 59.1)
    }

    // MARK: - Auth Header

    func testAuthHeaderSent() async throws {
        MockURLProtocol.requestHandler = { request in
            // Verificar que se envía el header de auth
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token-123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")

            let data = try JSONSerialization.data(withJSONObject: ["ok": true])
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let endpoint = await HTTPEndpoint(path: "/fx/latest", requiresAuth: true)
        _ = try await client.sendRaw(endpoint)
    }

    func testNoAuthHeaderForPublicEndpoint() async throws {
        MockURLProtocol.requestHandler = { request in
            // No debe enviar auth header
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))

            let data = try JSONSerialization.data(withJSONObject: ["status": "ok"])
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let endpoint = await HTTPEndpoint(path: "/health", requiresAuth: false)
        _ = try await client.sendRaw(endpoint)
    }

    // MARK: - Error Cases

    func testUnauthorized401() async {
        MockURLProtocol.setErrorResponse(
            statusCode: 401,
            code: "UNAUTHORIZED",
            message: "Missing or invalid API key"
        )

        let endpoint = await HTTPEndpoint(path: "/fx/latest", requiresAuth: true)

        do {
            _ = try await client.sendRaw(endpoint)
            XCTFail("Debió lanzar error")
        } catch let error as HTTPError {
            if case .unauthorized(let requestId) = error {
                XCTAssertEqual(requestId, "test-req-id")
            } else {
                XCTFail("Error incorrecto: \(error)")
            }
        } catch {
            XCTFail("Error inesperado: \(error)")
        }
    }

    func testRateLimited429() async {
        MockURLProtocol.setErrorResponse(
            statusCode: 429,
            code: "RATE_LIMITED",
            message: "Too many requests"
        )

        let endpoint = await HTTPEndpoint(path: "/fx/latest", requiresAuth: true)

        do {
            _ = try await client.sendRaw(endpoint)
            XCTFail("Debió lanzar error")
        } catch let error as HTTPError {
            if case .rateLimited(_, let requestId) = error {
                XCTAssertEqual(requestId, "test-req-id")
            } else {
                XCTFail("Error incorrecto: \(error)")
            }
        } catch {
            XCTFail("Error inesperado: \(error)")
        }
    }

    func testServerError500() async {
        MockURLProtocol.setErrorResponse(
            statusCode: 500,
            code: "INTERNAL_ERROR",
            message: "Internal server error"
        )

        let endpoint = await HTTPEndpoint(path: "/fx/latest", requiresAuth: true)

        do {
            _ = try await client.sendRaw(endpoint)
            XCTFail("Debió lanzar error")
        } catch let error as HTTPError {
            if case .serverError(let code, _, let requestId) = error {
                XCTAssertEqual(code, 500)
                XCTAssertEqual(requestId, "test-req-id")
            } else {
                XCTFail("Error incorrecto: \(error)")
            }
        } catch {
            XCTFail("Error inesperado: \(error)")
        }
    }

    // MARK: - Decoding

    func testDecodingFailure() async {
        // Responder con JSON que no coincide con el tipo esperado
        MockURLProtocol.setSuccessResponse(json: ["unexpected": "data"])

        struct StrictResponse: Decodable {
            let requiredField: String
        }

        let endpoint = await HTTPEndpoint(path: "/fx/latest", requiresAuth: true)

        do {
            let _: StrictResponse = try await client.send(endpoint, as: StrictResponse.self)
            XCTFail("Debió lanzar error de decodificación")
        } catch let error as HTTPError {
            if case .decodingFailed = error {
                // Correcto
            } else {
                XCTFail("Error incorrecto: \(error)")
            }
        } catch {
            XCTFail("Error inesperado: \(error)")
        }
    }
}
