SafeChat — AI-Powered Cyberbullying Detection System
A real-time messaging platform with an integrated AI agent pipeline that monitors, detects, and moderates cyberbullying behaviour across text, images, and emoji — built as a research and demonstration project.

Overview
SafeChat is a multimodal cyberbullying detection system that combines a fine-tuned deep learning model with an agentic AI orchestration layer. The system intercepts every message in real time, scores it across multiple modalities, and autonomously decides whether to warn, escalate, or restrict a user — all without requiring human intervention for routine moderation decisions.
The project addresses a core limitation of existing moderation tools: single-modality text classifiers that miss sarcasm, image-based harassment, and escalation patterns. SafeChat integrates vision, language, and behavioural context into a unified detection pipeline.

Architecture
Flutter Mobile App
        |
        v
Supabase (PostgreSQL + Realtime + Storage)
        |
        v
FastAPI Inference Server (HuggingFace Spaces)
        |
        v
LangGraph Agent Pipeline
   |            |            |            |
Detector     Analyser      Action      Report
Agent        Agent         Agent       Agent
(DistilBERT  (Groq LLM)   (Decision   (Admin
 + CLIP +                  Logic)      Summary)
 Sarcasm)
        |
        v
Admin Dashboard (Flutter)

Key Features
Multimodal Detection

OCR-based text extraction from meme images using Tesseract
CLIP zero-shot visual scoring for images with insufficient text
Fine-tuned DistilBERT classifier for caption and message text
Sarcasm and irony detection using a RoBERTa-based model
Weighted fusion of all modality scores into a single confidence value

Agentic AI Orchestration (LangGraph)

Detector Agent: scores message using all modalities
Analyser Agent: uses Groq LLM (LLaMA 3) to reason about behaviour patterns
Action Agent: autonomously decides moderation action based on context
Report Agent: generates human-readable admin summaries

Automated Escalation Pipeline

Warning 1 to 2: silent logging
Warning 3: AI surveillance alert shown to user in-app (one-time, permanent)
Warning 4 to 5: admin notified with option to send email warning
Warning 6 and above: admin notified with option to permanently block user
Block action deletes user data and prevents future login

Admin Dashboard

Tab 1 — Users: full user list with risk levels, tap for Groq-powered behaviour analysis
Tab 2 — Warnings: all flagged messages with scores and metadata
Tab 3 — Risk Distribution: bar chart showing High / Medium / Low / Clean user breakdown
Tab 4 — Alerts: actionable notifications for users requiring manual intervention

Real-Time Messaging

WebSocket-based message delivery via Supabase Realtime
AI inference runs in the background — message delivery is not blocked
Image sharing with OCR and CLIP analysis
Timestamps corrected to local timezone (IST)


Technology Stack
LayerTechnologyMobile FrontendFlutter (Dart)Backend / DatabaseSupabase (PostgreSQL, Realtime, Storage)AI Inference ServerFastAPI, Python 3.10Model DeploymentHuggingFace Spaces (Docker)Cyberbullying ClassifierDistilBERT (fine-tuned on cyberbullying dataset)Visual UnderstandingCLIP (openai/clip-vit-base-patch32)Sarcasm Detectioncardiffnlp/twitter-roberta-base-ironyOCRTesseract via pytesseractAgent OrchestrationLangGraphLLM BrainGroq API (LLaMA 3.3 70B)Email AutomationSMTP via Gmail App Password (mailer package)HTTP ClientDart http packageChartsfl_chart

Model Details
DistilBERT Cyberbullying Classifier

Base model: distilbert-base-uncased
Fine-tuned on a labelled cyberbullying dataset
Output: binary classification (cyberbullying / not cyberbullying) with softmax confidence score
Threshold: 0.50 weighted fusion score

Weighted Fusion
When OCR text is sufficient (4 or more words):

OCR score: 40%
Caption score: 40%
Emoji meaning score: 20%

When OCR text is insufficient (CLIP fallback):

CLIP visual score: 40%
Caption score: 45%
Emoji meaning score: 15%

Sarcasm Overlay

If sarcasm confidence exceeds 0.60 and weighted score is below 0.40, the message is reclassified as Harmless Sarcasm
If sarcasm is detected and weighted score exceeds 0.40, it is reclassified as Sarcastic Bullying


Project Structure
cyber_chat_ai/
├── lib/
│   ├── main.dart                        # App entry, constants, Supabase init
│   ├── models/
│   │   ├── user_model.dart
│   │   └── message_model.dart
│   ├── services/
│   │   ├── supabase_service.dart        # All DB operations
│   │   ├── ai_service.dart              # API calls, Groq analysis
│   │   └── email_service.dart           # SMTP email via Gmail
│   └── screens/
│       ├── auth/
│       │   └── login_screen.dart        # Login and registration with email
│       ├── chat/
│       │   ├── chat_screen.dart         # Real-time chat with background AI check
│       │   ├── users_list_screen.dart
│       │   └── widgets/
│       │       ├── message_bubble.dart
│       │       └── message_input.dart   # Text + image input with permissions
│       └── admin/
│           └── admin_dashboard.dart     # 4-tab admin panel
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── res/xml/network_security_config.xml
└── pubspec.yaml

Supabase Schema
sql-- Users table
create table users (
  id            uuid default gen_random_uuid() primary key,
  username      text unique not null,
  password      text not null,
  email         text default '',
  alert_shown   boolean default false,
  is_blocked    boolean default false,
  warning_count int default 0,
  created_at    timestamp default now()
);

-- Messages table
create table messages (
  id            uuid default gen_random_uuid() primary key,
  sender_id     uuid references users(id),
  receiver_id   uuid references users(id),
  text          text,
  image_url     text,
  flagged       boolean default false,
  bully_score   float default 0,
  sarcasm_type  text default 'None',
  prediction    text default 'Not Cyberbullying',
  created_at    timestamp default now()
);

-- Flags table
create table flags (
  id            uuid default gen_random_uuid() primary key,
  user_id       text,
  username      text,
  message_id    text,
  message_text  text,
  bully_score   float default 0,
  sarcasm_type  text default 'None',
  prediction    text default 'Cyberbullying',
  warning_count int default 1,
  severity      text default 'medium',
  action        text default 'warn',
  admin_report  text default '',
  mail_sent     boolean default false,
  notified      boolean default false,
  created_at    timestamp default now()
);

Setup and Configuration
1. Clone the repository
bashgit clone https://github.com/Dharsh-04/cyber_chat_ai.git
cd cyber_chat_ai
2. Configure credentials in lib/main.dart
dartconst String supabaseUrl     = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
const String ngrokApiUrl     = 'YOUR_HUGGINGFACE_OR_NGROK_URL';
const String geminiApiKey    = 'YOUR_GEMINI_API_KEY';
3. Configure Groq key in lib/services/ai_service.dart
dartconst groqKey = 'YOUR_GROQ_API_KEY';
4. Configure Gmail credentials in lib/services/email_service.dart
dartstatic const _fromEmail   = 'your_gmail@gmail.com';
static const _appPassword = 'your_16_digit_app_password';
5. Install dependencies and run
bashflutter pub get
flutter run

AI Inference Server Deployment
The FastAPI server is deployed on HuggingFace Spaces using Docker.
Required files in Space root:
app.py               # FastAPI routes + LangGraph pipeline
requirements.txt     # Python dependencies
Dockerfile           # Container configuration
model/               # Fine-tuned DistilBERT model files
  config.json
  model.safetensors
  tokenizer.json
  tokenizer_config.json
API Endpoints
GET  /health                  Health check
POST /predict/text            Text message scoring
POST /predict/multimodal      Image + caption + emoji scoring

Admin Credentials
The admin account is hardcoded and does not require registration.
Username : admin
Password : admin@safechat123

Escalation Logic Summary
Warning CountAction1 to 2Silent flag — admin can see in dashboard3AI surveillance alert shown to user in-app (one time only)4 to 5Admin notification — option to send warning email6 and aboveAdmin notification — option to block and delete user

Limitations and Future Work

The DistilBERT model was trained on English text only — multilingual support is not yet available
SMTP email delivery requires a Gmail account with App Password enabled
The HuggingFace free tier may throttle inference under high load
Passwords are stored as plain text — production deployment should use bcrypt hashing
The system currently supports one-to-one messaging only — group chat is not implemented
LangGraph agent reasoning latency depends on Groq API response time

