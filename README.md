# R Plumber API with Docker

A simple, secure web API that lets you run R scripts remotely. Built with R's plumber package and containerized with Docker.

## Features

- RESTful endpoint (`POST /modi`) that sums two numbers
- API key authentication
- Docker containerization
- Environment-based configuration
- Basic logging and monitoring

## Prerequisites

- Docker
- curl (for testing)

## Local Development

1. Clone this repository:
   ```bash
   git clone <your-repo-url>
   cd rskeleton
   ```

2. Create a `.env` file in the project root:
   ```
   API_KEY=your_local_test_key
   PORT=8000
   ```

3. Build the Docker image:
   ```bash
   docker build -t rskeleton:latest .
   ```

4. Run the container:
   ```bash
   docker run -p 8000:8000 --env-file .env rskeleton:latest
   ```

5. Test the API:
   ```bash
   # Health check
   curl http://localhost:8000/health

   # Sum two numbers
   curl -X POST http://localhost:8000/modi \
     -H "x-api-key: your_local_test_key" \
     -H "Content-Type: application/json" \
     -d '{"a": 3, "b": 5}'
   ```

## API Endpoints

### GET /health
Health check endpoint. Returns server status and timestamp.

### POST /modi
Sums two numbers.

**Headers:**
- `Content-Type: application/json`
- `x-api-key: YOUR_API_KEY`

**Request Body:**
```json
{
  "a": number,
  "b": number
}
```

**Response:**
```json
{
  "result": number
}
```

## Deployment

The API is deployed on DigitalOcean App Platform. The deployment process is automated through DigitalOcean's integration with Docker.

## Security

- API key authentication required for all endpoints except /health
- Runs as non-root user in Docker
- Environment-based configuration
- HTTPS enforced in production

## Monitoring

Basic monitoring is available through DigitalOcean's App Platform dashboard:
- CPU and memory usage
- Request logs
- Error rates

## License

MIT 