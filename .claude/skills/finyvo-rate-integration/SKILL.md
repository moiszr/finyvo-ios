---
name: finyvo-rate-integration
description: Integration contract for the FinyvoRate FX API (auth, endpoints, caching, retries, errors, conversion) for any client or assistant.
---

# FinyvoRate Integration Skill (Universal AI + Any Client)

Purpose: this document is the exact integration contract for `finyvo-rate-api`, designed so any AI assistant or developer can integrate safely without missing auth, request shape, error handling, or operational details.

Base URL (production): `https://rate.finyvo.com`

## 1) Non-Negotiable Integration Rules

1. Always send `Authorization: Bearer <TOKEN>` for every `/fx/*` request.
2. Never send API keys to logs, analytics, crash reports, or client-visible errors.
3. Treat `/health` as the only public endpoint.
4. Always parse and propagate `error.code`, `error.message`, and `error.requestId` on failures.
5. Use retries only for transient failures (`429`, `5xx`, network timeout); never retry `401` blindly.

## 2) Authentication Contract (Exact)

Protected routes: all `/fx/*`

Public route: `/health`

### Header format

```http
Authorization: Bearer <TOKEN>
```

### Server-side validation model

The backend validates tokens in `AUTH_KV` by key:

- KV key: `api_key:<TOKEN>`
- KV value JSON (minimum required fields):

```json
{
  "name": "ios-prod",
  "enabled": true,
  "createdAt": "2026-02-12T00:00:00Z"
}
```

Access is allowed only when record exists and `enabled === true`.

### Unauthorized response

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Missing or invalid API key",
    "requestId": "..."
  }
}
```

Status: `401`

## 3) Global Error Contract

All errors follow this schema:

```json
{
  "error": {
    "code": "...",
    "message": "...",
    "requestId": "..."
  }
}
```

Common status/code pairs:

- `400 INVALID_PARAMS`
- `401 UNAUTHORIZED`
- `404 NOT_FOUND`
- `429 RATE_LIMITED`
- `502 UPSTREAM_ERROR`
- `500 INTERNAL_ERROR`

## 4) Endpoint Catalog (Exact Behavior)

## Public

### `GET /health`

No auth required.

#### Example

```bash
curl -i "https://rate.finyvo.com/health"
```

## Protected

### `GET /fx/latest`

Returns latest snapshot rates.

#### Query params

- `currencies` (optional): CSV like `EUR,DOP`
- `base` (accepted by validation but ignored by backend for this route)

#### Response shape

```json
{
  "base": "USD",
  "requestedDate": "YYYY-MM-DD",
  "dateUsed": "YYYY-MM-DD",
  "rates": { "EUR": 0.92, "DOP": 59.1 },
  "provider": "exchangerate.host",
  "fetchedAt": "ISO",
  "isEstimated": false,
  "source": "kv"
}
```

`source` is `"kv"` or `"upstream"`.

#### Example

```bash
curl -i -H "Authorization: Bearer <TOKEN>" \
  "https://rate.finyvo.com/fx/latest?currencies=EUR,DOP"
```

---

### `GET /fx/date/:date`

Returns historical rates for a day (with fallback to nearest prior available day).

#### Path params

- `date` required, format `YYYY-MM-DD`

#### Query params

- `currencies` optional CSV
- `base` accepted by validation but ignored by backend for this route

#### Response shape

```json
{
  "base": "USD",
  "requestedDate": "YYYY-MM-DD",
  "dateUsed": "YYYY-MM-DD",
  "rates": { "EUR": 0.91 },
  "provider": "exchangerate.host",
  "fetchedAt": "ISO",
  "isEstimated": true,
  "source": "d1+upstream"
}
```

`source` is `"d1"` or `"d1+upstream"`.

#### Example

```bash
curl -i -H "Authorization: Bearer <TOKEN>" \
  "https://rate.finyvo.com/fx/date/2026-02-02?currencies=EUR,DOP"
```

---

### `GET /fx/timeframe`

Returns rates by day for a date range.

#### Query params

- `start` required `YYYY-MM-DD`
- `end` required `YYYY-MM-DD`
- `currencies` optional CSV
- `base` optional; **currently honored if provided on this route**

#### Response shape

```json
{
  "base": "USD",
  "start": "YYYY-MM-DD",
  "end": "YYYY-MM-DD",
  "ratesByDate": {
    "YYYY-MM-DD": { "EUR": 0.9, "DOP": 58.8 }
  },
  "provider": "exchangerate.host",
  "fetchedAt": "ISO",
  "source": "d1"
}
```

`source` is `"d1"` or `"d1+upstream"`.

#### Example

```bash
curl -i -H "Authorization: Bearer <TOKEN>" \
  "https://rate.finyvo.com/fx/timeframe?start=2026-02-01&end=2026-02-10&currencies=EUR,DOP"
```

---

### `GET /fx/convert`

Performs amount conversion using latest or historical rates.

#### Query params

- `from` required (3-letter currency)
- `to` required (3-letter currency)
- `amount` required (number)
- `date` optional (`YYYY-MM-DD`)
- `base` accepted by validation but ignored by backend for this route

#### Conversion math (current implementation)

Given `base` and rates map:

- If `from == to`: `rate = 1`
- If `from == base`: `rate = rates[to]`
- If `to == base`: `rate = 1 / rates[from]`
- Else: `rate = rates[to] / rates[from]`

`result = amount * rate`

#### Response shape

```json
{
  "from": "DOP",
  "to": "USD",
  "amount": 1000,
  "rate": 0.016,
  "result": 16,
  "base": "USD",
  "requestedDate": "YYYY-MM-DD",
  "dateUsed": "YYYY-MM-DD",
  "provider": "exchangerate.host",
  "fetchedAt": "ISO",
  "isEstimated": true,
  "source": "d1+upstream"
}
```

#### Examples

```bash
curl -i -H "Authorization: Bearer <TOKEN>" \
  "https://rate.finyvo.com/fx/convert?from=DOP&to=USD&amount=1000"

curl -i -H "Authorization: Bearer <TOKEN>" \
  "https://rate.finyvo.com/fx/convert?from=COP&to=EUR&amount=500&date=2026-02-02"
```

---

### `GET /fx/symbols`

Returns symbol dictionary.

#### Response shape

```json
{
  "symbols": {
    "USD": "United States Dollar"
  },
  "provider": "exchangerate.host",
  "fetchedAt": "ISO",
  "source": "kv"
}
```

`source` is `"kv"` or `"upstream"`.

#### Example

```bash
curl -i -H "Authorization: Bearer <TOKEN>" \
  "https://rate.finyvo.com/fx/symbols"
```

## 5) Operational Characteristics You Must Respect

1. Rate limiting is enabled (default `60 req/min per IP`).
2. 401 spikes, 5xx responses, and rate-limit events may trigger server-side alerts.
3. Latest data is cached in KV snapshot; historical data is sourced from D1 with upstream fill on misses.
4. For historical fallback (holidays/weekends), response may set `isEstimated=true` and `dateUsed` earlier than requested date.

## 6) Reference Integration (TypeScript)

```ts
const API_BASE = 'https://rate.finyvo.com';
const API_TOKEN = process.env.FINYVO_RATE_TOKEN!;

type ApiError = {
  error: { code: string; message: string; requestId: string };
};

async function finyvoFetch<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: {
      Authorization: `Bearer ${API_TOKEN}`,
      Accept: 'application/json'
    }
  });

  const data = await res.json();

  if (!res.ok) {
    const err = data as ApiError;
    throw new Error(
      `[${err.error?.code ?? res.status}] ${err.error?.message ?? 'Request failed'} (requestId=${err.error?.requestId ?? 'n/a'})`
    );
  }

  return data as T;
}

// Example usage:
// const latest = await finyvoFetch('/fx/latest?currencies=EUR,DOP');
```

## 7) Reference Integration (Swift)

```swift
import Foundation

struct APIErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let code: String
        let message: String
        let requestId: String
    }
    let error: APIError
}

func finyvoRequest(path: String, token: String) async throws -> Data {
    guard let url = URL(string: "https://rate.finyvo.com\(path)") else {
        throw URLError(.badURL)
    }

    var req = URLRequest(url: url)
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: req)
    guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

    if !(200...299).contains(http.statusCode) {
        if let apiErr = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
            throw NSError(domain: "FinyvoRate", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "[\(apiErr.error.code)] \(apiErr.error.message) requestId=\(apiErr.error.requestId)"
            ])
        }
        throw NSError(domain: "FinyvoRate", code: http.statusCode)
    }

    return data
}
```

## 8) AI-Agent Prompt Contract (Copy/Paste)

Use this when giving tasks to Claude/ChatGPT/Copilot:

```text
You are integrating against FinyvoRate API.

Hard requirements:
1) Base URL: https://rate.finyvo.com
2) /health is public; every /fx/* call MUST send Authorization: Bearer <TOKEN>
3) Never print or expose the token
4) Parse API error envelope exactly: { error: { code, message, requestId } }
5) On 401: stop and request valid token
6) On 429/5xx: retry with backoff (max 2-3 attempts), then fail with requestId
7) Respect endpoint contracts from FINYVO_RATE_INTEGRATION_SKILL.md
8) For currency conversions, prefer /fx/convert instead of client-side math
```

## 9) “Skill” Block for Claude Projects (Template)

You can paste this as a local project skill instruction:

```md
# Skill: finyvo-rate-integration

When interacting with FX data, always use FinyvoRate backend.

- Base URL: https://rate.finyvo.com
- Public endpoint: GET /health
- Protected endpoints: GET /fx/latest, /fx/date/:date, /fx/timeframe, /fx/convert, /fx/symbols
- Required header for protected endpoints: Authorization: Bearer <TOKEN>
- Error shape: { error: { code, message, requestId } }
- Never leak API token in outputs/logs.
- If receiving 401, ask user to provide/refresh token.
- If receiving 429/5xx, retry with brief exponential backoff and include requestId in failure summary.
```

## 10) Quick Validation Checklist

1. `GET /health` works without token.
2. `GET /fx/latest` fails with `401` without token.
3. `GET /fx/latest` succeeds with token.
4. `GET /fx/convert` returns expected numeric result and includes `rate`, `result`, `dateUsed`.
5. All error handling in client surfaces `requestId`.

---

If this document and runtime differ, runtime behavior is authoritative. Update this file immediately after backend changes.

