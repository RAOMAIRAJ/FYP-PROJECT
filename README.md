# Qanoon Buddy - Legal Chatbot & Directory ⚖️🤖

**Qanoon Buddy** is a comprehensive full-stack legal application built as a Final Year Project. It connects users with verified lawyers, provides a peer-to-peer workspace for communication, and includes an intelligent bilingual (English & Urdu) Legal Chatbot powered by Google Gemini and LangChain RAG.

## 🌟 Key Features

### 1. 🤖 AI Legal Chatbot (RAG)
- **Bilingual Interface**: Answers queries in English and Roman Urdu.
- **Context-Aware Memory**: Remembers your legal scenario across a session.
- **Speech-to-Text**: Voice typing natively supported for users who cannot type long questions.

### 2. 👩‍⚖️ Lawyer Directory & Matchmaking
- **Browse & Filter**: Find specialized lawyers based on city, years of experience, and practice areas.
- **Consultation Bookings**: Schedule online or in-person meetings with verified lawyers.
- **Review System**: Clients can rate and review their lawyers upon completing a case.

### 3. 💬 Peer-to-Peer Encrypted Chat
- **Sockets-based Messaging**: Real-time communication between users and lawyers via WebSocket.
- **Push Notifications**: Receive prompt alerts when a lawyer accepts your case or sends a message.

### 4. 📄 AI Document Analyzer
- **PDF Legal Document Scanning**: Upload legal notices and contracts to automatically extract summaries and risk assessments.
- **OCR Engine**: Utilizes Tesseract and Gemini to quickly parse and translate heavy legal jargon.

### 5. 🛡️ Admin & Lawyer Dashboards
- **Dedicated Lawyer Panel**: Accept/Reject consultation requests, and track total earnings/ratings.
- **Admin Approval System**: Verifies lawyer Bar Council documents before letting them appear in the directory.

---

## 🏗️ Architecture Stack

The project relies on a Microservices-inspired architecture:

### Frontend (User & Lawyer Apps)
- **Framework**: `Flutter` and `Riverpod` (State Management)
- **Deployment**: Android APK, iOS, Web

### Core Backend (User Management, Bookings, Sockets)
- **Framework**: `FastAPI` (Python)
- **Database**: `SQLite/PostgreSQL` via SQLAlchemy ORM.
- **Realtime**: WebSockets

### AI / NLP Microservice (RAG, Chatbot, OCR)
- **Framework**: `FastAPI` + `LangChain`
- **LLM**: Google `Gemini 1.5 Pro`
- **Vector Store**: `ChromaDB` (Document embeddings)

---

## 🚀 Getting Started

Follow these steps to boot the entire ecosystem locally.

### 1. Core Backend
```bash
cd qanoon-buddy-backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. NLP / Chatbot Microservice
```bash
cd qanoon-buddy-nlp
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
# Ensure your .env contains GEMINI_API_KEY
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

### 3. Flutter App
```bash
cd qanoon_buddy
flutter pub get
flutter run -d chrome
# To build an Android APK:
# flutter build apk --release
```

## 🔐 Credentials for Testing

- **Admin Account**: `admin@qanoonbuddy.com` (Pass: `admin123`)
- **Lawyer Account**: `lawyer@qanoonbuddy.com` (Pass: `lawyer123`)
- **User Account**: `user@qanoonbuddy.com` (Pass: `user123`)

---

> **Note to Reviewers**: Qanoon Buddy's AI is built strictly for advisory and preliminary consultation purposes and does not substitute a licensed legal practitioner's formal counsel in court.
