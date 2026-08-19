# Rafeeq

**Rafeeq (رفيق)** is an AI-powered recovery support platform that helps people recovering from addiction document and reflect on their daily experiences through text and voice journaling.

The platform uses speech-to-text and generative AI to analyze journal entries and provide useful insights such as mood, summaries, keywords, and potential relapse indicators.

[Watch the project demo](./video_2026-08-06_17-37-35.mp4)

## Features

* Text and voice journaling
* Voice-to-text transcription
* AI-powered journal analysis
* Mood tracking
* Supportive AI chat
* Support and emergency resources
* Background audio processing
* User authentication
* Cloud-compatible audio storage

## Tech Stack

**Frontend**

* Flutter
* Dart

**Backend**

* FastAPI
* Python
* JWT

**Database**

* PostgreSQL
* SQLAlchemy
* Alembic

**Processing & Storage**

* Redis
* Celery
* MinIO / S3

**AI**

* Whisper
* Gemini

## Project Structure

```text
raffeq/
├── app/                 # FastAPI backend
│   ├── api/
│   ├── core/
│   ├── db/
│   ├── schemas/
│   ├── services/
│   ├── worker/
│   └── main.py
│
├── alembic/             # Database migrations
│
├── rafeeqapp/           # Flutter application
│
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── alembic.ini
```

## Getting Started

### Requirements

* Python
* Flutter
* Docker
* PostgreSQL
* Redis
* MinIO / S3-compatible storage

### Clone

```bash
git clone https://github.com/sharshabil1/raffeq.git
cd raffeq
```

### Backend

Install dependencies:

```bash
pip install -r requirements.txt
```

Run migrations:

```bash
alembic upgrade head
```

Start the API:

```bash
uvicorn app.main:app --reload
```

API:

```text
http://localhost:8000
```

API documentation:

```text
http://localhost:8000/docs
```

### Flutter

```bash
cd rafeeqapp
flutter pub get
flutter run
```

## Docker

Build and start the services:

```bash
docker compose up --build -d
```

Check the containers:

```bash
docker compose ps
```

Stop the services:

```bash
docker compose down
```

## Environment Configuration

Configure the required environment variables for:

* Database
* JWT authentication
* Redis
* MinIO / S3
* AI services

Keep credentials and API keys in environment variables rather than committing them to the repository.

## AI Processing

Voice journals follow this process:

```text
Voice Recording
      ↓
   Storage
      ↓
Redis + Celery
      ↓
    Whisper
      ↓
  Transcript
      ↓
    Gemini
      ↓
AI Analysis
```

The analysis is used by the application to provide journal insights and support the user's recovery journey.

## Important

Rafeeq is a supportive AI tool for self-reflection and recovery support. It does not replace professional medical or psychological care and should not be used as an emergency service.

## Repository

https://github.com/sharshabil1/raffeq
