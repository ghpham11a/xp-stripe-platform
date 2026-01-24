from fastapi import FastAPI
from contextlib import asynccontextmanager
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from routers import accounts, payment_methods, external_accounts, transactions


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Starting up...")
    yield
    print("Shutting down...")


def create_app() -> FastAPI:
    app = FastAPI(
        title="Stripe Connect Demo API",
        lifespan=lifespan,
    )

    @app.get("/")
    def root():
        return {"status": "up"}

    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["http://localhost:3000"],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
        allow_headers=["Content-Type"],
    )

    # Register routers
    app.include_router(accounts.router)
    app.include_router(payment_methods.router)
    app.include_router(external_accounts.router)
    app.include_router(transactions.router)

    return app


load_dotenv()

# uvicorn main:app --host 0.0.0.0 --port 6969 --reload
app = create_app()
