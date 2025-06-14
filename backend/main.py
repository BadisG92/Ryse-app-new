from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.security import HTTPBearer
import os
import time
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import routers
from routers import auth, users, exercises, workouts, hiit, cardio, mobile
from nutrition_api import nutrition_router
from exercise_api import router as exercise_router
from workout_templates_api import router as workout_templates_router
from realtime_api import router as realtime_router
from custom_content_api import router as custom_content_router
from external_services_api import router as external_services_router

# Initialize FastAPI app
app = FastAPI(
    title="Ryze API",
    description="API backend for Ryze fitness and nutrition app",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add GZip compression for mobile data savings
app.add_middleware(GZipMiddleware, minimum_size=1000)

# CORS middleware with mobile-specific headers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Total-Count", "X-Page", "X-Per-Page"]  # For pagination info
)

# Performance monitoring middleware
@app.middleware("http")
async def add_process_time_header(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

# Security
security = HTTPBearer()

# Include routers with API versioning
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(exercises.router, prefix="/api/v1/exercises", tags=["Exercises"])
app.include_router(workouts.router, prefix="/api/v1/workouts", tags=["Workouts"])
app.include_router(hiit.router, prefix="/api/v1/hiit", tags=["HIIT"])
app.include_router(cardio.router, prefix="/api/v1/cardio", tags=["Cardio"])
app.include_router(nutrition_router, tags=["Nutrition"])
app.include_router(exercise_router, tags=["Exercise Module"])
app.include_router(workout_templates_router, tags=["Workout Templates"])
app.include_router(realtime_router, tags=["Real-time Sync"])
app.include_router(custom_content_router, tags=["Custom Content"])
app.include_router(external_services_router, tags=["External Services"])
app.include_router(mobile.router, prefix="/api/v1/mobile", tags=["Mobile"])

@app.get("/")
async def root():
    return {
        "message": "Welcome to Ryze API",
        "version": "1.0.0",
        "docs": "/docs",
        "mobile_optimized": True
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy", 
        "service": "ryze-api",
        "timestamp": time.time(),
        "mobile_features": {
            "compression": True,
            "caching": True,
            "offline_sync": "planned"
        }
    }

# Mobile-specific endpoints
@app.get("/api/v1/mobile/sync-status")
async def get_sync_status():
    """Get synchronization status for offline mobile app"""
    return {
        "last_sync": time.time(),
        "pending_uploads": 0,
        "server_version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True) 