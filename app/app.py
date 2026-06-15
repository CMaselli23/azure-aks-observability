import time
import random
from fastapi import FastAPI, Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = FastAPI()

# --- Prometheus metrics ---
REQUEST_COUNT = Counter(
    "app_requests_total",
    "Total number of requests",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds",
    "Request latency in seconds",
    ["endpoint"]
)

ERROR_COUNT = Counter(
    "app_errors_total",
    "Total number of errors",
    ["endpoint"]
)


# --- Routes ---
@app.get("/")
def root():
    start = time.time()
    REQUEST_COUNT.labels(method="GET", endpoint="/", status="200").inc()
    REQUEST_LATENCY.labels(endpoint="/").observe(time.time() - start)
    return {"status": "ok", "service": "maselli-metrics-app"}


@app.get("/api/data")
def get_data():
    start = time.time()

    # Simulate 10% error rate
    if random.random() < 0.10:
        ERROR_COUNT.labels(endpoint="/api/data").inc()
        REQUEST_COUNT.labels(method="GET", endpoint="/api/data", status="500").inc()
        REQUEST_LATENCY.labels(endpoint="/api/data").observe(time.time() - start)
        return Response(content="Internal Server Error", status_code=500)

    # Simulate variable latency 10-300ms
    latency = random.uniform(0.01, 0.30)
    time.sleep(latency)

    REQUEST_COUNT.labels(method="GET", endpoint="/api/data", status="200").inc()
    REQUEST_LATENCY.labels(endpoint="/api/data").observe(time.time() - start)
    return {"status": "ok", "latency_ms": round(latency * 1000, 2)}


@app.get("/metrics")
def metrics():
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )