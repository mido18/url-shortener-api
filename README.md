# URL Shortener API

A high-performance URL shortening service built with Ruby on Rails, featuring Redis caching and Base62 encoding for compact URLs.

## Features

- **URL Encoding**: Convert long URLs into short, shareable links
- **URL Decoding**: Retrieve original URLs from short links
- **Redis Caching**: Fast lookups with automatic cache management
- **Base62 Encoding**: 6-character alphanumeric slugs using sequential IDs with offset
- **Duplicate Prevention**: Reuses existing short links for the same URL
- **Atomic Counter**: Redis-based counter ensures unique slug generation

## API Endpoints

### Encode URL

Create a short URL from a long URL.

**Endpoint:** `POST /api/v1/encode`

**Request:**
```json
{
  "url": "https://example.com/very/long/path?with=parameters"
}
```

**Response:**
```json
{
  "short_url": "http://localhost:3000/a00001"
}
```

**Error Response:**
```json
{
  "error": ["Original url can't be blank"]
}
```

### Decode URL

Retrieve the original URL from a short link. Supports two methods:

#### Method 1: By Slug Parameter

**Endpoint:** `GET /api/v1/decode/:slug`

**Example:** `GET /api/v1/decode/a00001`

**Response:**
```json
{
  "original_url": "https://example.com/very/long/path?with=parameters"
}
```

#### Method 2: By URL Query Parameter

Decode short URLs by passing the complete short URL.

**Endpoint:** `GET /api/v1/decode?url=<short_url>`

**Example:**
```bash
GET /api/v1/decode?url=http://localhost:3000/a00001
```

**Response:**
```json
{
  "original_url": "https://example.com/very/long/path?with=parameters"
}
```

**Error Response:**
```json
{
  "error": "Short URL not found"
}
```

**Note:** The URL query parameter method only accepts short URLs for decoding. Original URLs are not supported.

## Backward Compatibility

For backward compatibility, legacy endpoints are available that route directly to the versioned API:

- `POST /encode` → routes to `POST /api/v1/encode`
- `GET /decode/:slug` → routes to `GET /api/v1/decode/:slug`
- `GET /decode?url=...` → routes to `GET /api/v1/decode?url=...`

**Note:** These legacy endpoints (`/encode` and `/decode`) are provided to follow the original requirements document which specified these exact paths. However, **we strongly recommend using the versioned endpoints** (`/api/v1/encode` and `/api/v1/decode`) for new integrations as they follow REST API best practices and provide better future-proofing.

### Migration Guide

**Legacy (not recommended for new projects):**
```bash
# Legacy endpoints
curl -X POST http://localhost:3000/encode
curl http://localhost:3000/decode/a00001
```

**Recommended (use for new integrations):**
```bash
# Versioned endpoints (recommended)
curl -X POST http://localhost:3000/api/v1/encode
curl http://localhost:3000/api/v1/decode/a00001
```

Existing clients will continue to work without modification, but updating to versioned endpoints is recommended for better API evolution support.

## API Documentation

Interactive API documentation is available via Swagger UI:

**Access Swagger UI:** http://localhost:3000/api-docs

### Features:
- **Interactive testing** - Try API endpoints directly from the browser
- **Complete documentation** - All endpoints with request/response examples
- **Schema validation** - See required parameters and data types
- **Legacy endpoints** - Both versioned and legacy endpoints documented

### Usage:
1. Start the Rails server: `rails server`
2. Open http://localhost:3000/api-docs in your browser
3. Expand endpoint sections to see details
4. Click "Try it out" to test endpoints interactively
5. View request/response examples and schemas

## Setup

### Prerequisites

- Ruby 3.x
- Rails 7.x
- Redis server
- SQLite3 (development) or PostgreSQL (production)

### Installation

#### Option 1: Docker (Recommended)

1. Clone the repository:
```bash
git clone <repository-url>
cd url-shortener-api
```

2. Start with Docker:
```bash
./bin/docker-setup
```

3. Run tests:
```bash
./bin/docker-test
```

#### Option 2: Local Development

1. Clone the repository:
```bash
git clone <repository-url>
cd url-shortener-api
```

2. Install dependencies:
```bash
bundle install
```

3. Setup database:
```bash
rails db:create
rails db:migrate
```

4. Start Redis server:
```bash
redis-server
```

5. Start the Rails server:
```bash
rails server
```

### Environment Configuration

Create environment-specific files:

**.env.development**
```
REDIS_URL=redis://localhost:6379/0
```

**.env.test**
```
REDIS_URL=redis://localhost:6379/1
```

**.env.production**
```
REDIS_URL=redis://your-production-host:6379/0
```

## Usage Examples

### cURL Examples

**Encode a URL:**
```bash
curl -X POST http://localhost:3000/api/v1/encode \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.google.com/search?q=ruby+on+rails"}'
```

**Decode by slug:**
```bash
curl http://localhost:3000/api/v1/decode/a00001
```

**Decode by URL (short URL only):**
```bash
curl "http://localhost:3000/api/v1/decode?url=http://localhost:3000/a00001"
```

### JavaScript Examples

**Encode a URL:**
```javascript
fetch('http://localhost:3000/api/v1/encode', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ url: 'https://example.com' })
})
.then(response => response.json())
.then(data => console.log(data.short_url));
```

**Decode a URL:**
```javascript
fetch('http://localhost:3000/api/v1/decode/a00001')
.then(response => response.json())
.then(data => console.log(data.original_url));
```

## Architecture

### Caching Strategy

- **Encode**: Caches URL → slug and slug → URL mappings
- **Decode**: Uses cached mappings for instant lookups
- **Fallback**: Database queries when cache misses occur
- **Auto-caching**: Database results are automatically cached

### URL Generation

- Uses Redis atomic increment for unique sequential IDs
- Base62 encoding with large offset (9+ billion) ensures 6-character alphanumeric slugs
- Sequential generation: 1 → "a00001", 2 → "a00002", etc.
- Guaranteed format: always 6 characters with mixed letters and numbers

### Database Schema

```ruby
create_table :short_links do |t|
  t.text :original_url, null: false
  t.string :slug, null: false
  t.timestamps
end

add_index :short_links, :original_url, unique: true
add_index :short_links, :slug, unique: true
```

## Testing

### Docker
```bash
# Run all tests
./bin/docker-test

# Run specific test files
docker-compose run --rm test bundle exec rspec spec/models/short_link_spec.rb
```

### Local
```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/short_link_spec.rb
bundle exec rspec spec/requests/encode_spec.rb
bundle exec rspec spec/requests/decode_spec.rb
```

## Performance

- **Cache Hit**: ~1ms response time
- **Cache Miss**: ~10-50ms (includes database query + caching)
- **Concurrent Safe**: Redis atomic operations prevent race conditions
- **Collision Free**: Large offset ensures no slug conflicts
- **Memory Efficient**: 6-character slugs provide 56+ billion unique combinations

## Error Handling

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 400 | Bad Request (missing parameters) |
| 404 | Not Found (invalid slug/URL) |
| 422 | Unprocessable Entity (validation errors) |

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request
