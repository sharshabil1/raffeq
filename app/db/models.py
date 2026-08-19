import enum
import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()

class JobStatus(enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    jobs = relationship("AnalysisJob", back_populates="user", cascade="all, delete-orphan")
    chat_messages = relationship("ChatMessage", back_populates="user", cascade="all, delete-orphan")
    profile = relationship("UserProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")

class AnalysisJob(Base):
    __tablename__ = "analysis_jobs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    job_type = Column(String, default="audio") # لمعرفة إذا كان الطلب صوت أم نص
    file_url = Column(String, nullable=True)   # رابط ملف MinIO (فارغ إذا كان نص)
    text_prompt = Column(Text, nullable=True)  # النص المكتوب (فارغ إذا كان ملف صوتي)
    status = Column(Enum(JobStatus), default=JobStatus.PENDING, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="jobs")
    result = relationship("AIResult", back_populates="job", uselist=False, cascade="all, delete-orphan")

class AIResult(Base):
    __tablename__ = "ai_results"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    job_id = Column(UUID(as_uuid=True), ForeignKey("analysis_jobs.id"), nullable=False, unique=True)
    transcription = Column(Text, nullable=True)
    insights = Column(JSONB, nullable=True)

    job = relationship("AnalysisJob", back_populates="result")

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    role = Column(String, nullable=False) # "user" or "assistant"
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="chat_messages")

class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, unique=True, index=True)
    onboarding_data = Column(JSONB, nullable=True) # Immutable baseline answers (what brings you, goals, triggers)
    dynamic_state = Column(JSONB, nullable=True)   # Mutable state updated by AI (mood trends, active triggers, current focus)
    recovery_phase = Column(String, default="early_recovery") # e.g. early_recovery, maintenance, crisis_watch
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="profile")
    history = relationship("ProfileHistory", back_populates="profile", cascade="all, delete-orphan")

class ProfileHistory(Base):
    __tablename__ = "profile_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("user_profiles.id"), nullable=False, index=True)
    dynamic_state_snapshot = Column(JSONB, nullable=False)
    recovery_phase_snapshot = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)

    profile = relationship("UserProfile", back_populates="history")
