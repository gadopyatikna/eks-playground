# ClientWebApi

Minimal .NET API for the EKS workload.

Run locally from the repository root:

```bash
dotnet run --project app/src/ClientWebApi
curl http://localhost:8080/ready
```

Build and run its container image:

```bash
docker build --file app/Dockerfile --tag client-web-api app
docker run --rm --publish 8080:8080 client-web-api
```

- `GET /` returns the service identity.
- `GET /health` is the liveness endpoint.
- `GET /ready` is the readiness endpoint.
