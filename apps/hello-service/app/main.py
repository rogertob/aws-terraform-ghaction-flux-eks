from fastapi import FastAPI

app = FastAPI(title="hello-service")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/hello")
def hello(name: str = "world"):
    return {"message": f"Hello, {name}!"}
