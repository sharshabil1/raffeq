from fastapi import APIRouter
from app.api.v1 import auth, jobs, journals, chat, support, profile

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(jobs.router, prefix="/jobs", tags=["jobs"])
api_router.include_router(journals.router, prefix="/journals", tags=["journals"])
api_router.include_router(chat.router, prefix="/chat", tags=["chat"])
api_router.include_router(support.router, prefix="/support", tags=["support"])
api_router.include_router(profile.router, prefix="/profile", tags=["profile"])
