# **SafeChat — AI-Powered Cyberbullying Detection System**

## **Overview**

SafeChat is a real-time messaging platform integrated with an AI-driven moderation system that detects and manages cyberbullying across text, images, and emojis. It is designed as a research and demonstration project to address the limitations of traditional moderation systems.

Unlike conventional tools that rely solely on text-based classification, SafeChat combines multimodal analysis and behavioral tracking to detect sarcasm, image-based harassment, and repeated abusive patterns. The system operates autonomously, reducing the need for manual moderation in routine cases.

---

## **System Architecture**

```
Flutter Mobile App
        │
        ▼
Supabase (PostgreSQL, Realtime, Storage)
        │
        ▼
FastAPI Inference Server (HuggingFace Spaces)
        │
        ▼
LangGraph Agent Pipeline
   ├── Detector Agent (DistilBERT, CLIP, OCR)
   ├── Analyser Agent (Groq LLM - LLaMA 3)
   ├── Action Agent (Decision Logic)
   └── Report Agent (Admin Summary)
        │
        ▼
Admin Dashboard (Flutter)
```

---

## **Key Features**

### **1. Multimodal Detection**

* OCR-based text extraction from images using Tesseract
* CLIP-based visual understanding for image-only content
* Fine-tuned DistilBERT model for text classification
* Sarcasm detection using a RoBERTa-based model
* Weighted fusion of all modalities into a unified confidence score

---

### **2. Agentic AI Orchestration (LangGraph)**

* **Detector Agent**: Scores input across text, image, and emoji modalities
* **Analyser Agent**: Uses LLaMA 3 via Groq API to interpret behavior patterns
* **Action Agent**: Determines moderation action based on severity and history
* **Report Agent**: Generates structured summaries for admin review

---

### **3. Automated Escalation Pipeline**

| Warning Count | Action                                                 |
| ------------- | ------------------------------------------------------ |
| 1–2           | Silent logging (admin-visible only)                    |
| 3             | AI surveillance warning shown to user (one-time alert) |
| 4–5           | Admin notified with option to send warning email       |
| 6+            | Admin notified with option to block user permanently   |

Blocking prevents login and removes access to the platform.

---

### **4. Admin Dashboard**

* **Users Tab**: Displays all users with risk levels and behavior insights
* **Warnings Tab**: Shows flagged messages with scores and metadata
* **Risk Distribution Tab**: Visual breakdown of user risk categories
* **Alerts Tab**: Actionable notifications for escalation decisions

---

### **5. Real-Time Messaging**

* WebSocket-based communication using Supabase Realtime
* Non-blocking AI inference (messages are delivered instantly)
* Image sharing with OCR and visual analysis
* Timezone-aware timestamps (IST support)

---

## **Technology Stack**

| Layer             | Technology                               |
| ----------------- | ---------------------------------------- |
| Frontend          | Flutter (Dart)                           |
| Backend           | Supabase (PostgreSQL, Realtime, Storage) |
| AI Server         | FastAPI (Python 3.10)                    |
| Deployment        | HuggingFace Spaces (Docker)              |
| Text Model        | DistilBERT (fine-tuned)                  |
| Vision Model      | CLIP (ViT-B/32)                          |
| Sarcasm Detection | RoBERTa (Twitter Irony Model)            |
| OCR               | Tesseract                                |
| AI Orchestration  | LangGraph                                |
| LLM Reasoning     | Groq API (LLaMA 3.3 70B)                 |
| Email Service     | SMTP (Gmail App Password)                |
| Charts            | fl_chart                                 |

---

## **Model Design**

### **DistilBERT Classifier**

* Base Model: distilbert-base-uncased
* Task: Binary classification (Cyberbullying / Not Cyberbullying)
* Output: Softmax probability score
* Threshold: 0.50

---

### **Weighted Fusion Strategy**

**When OCR text is sufficient (≥ 4 words):**

* OCR Text Score: 40%
* Caption Score: 40%
* Emoji Score: 20%

**When OCR text is insufficient:**

* CLIP Visual Score: 40%
* Caption Score: 45%
* Emoji Score: 15%

---

### **Sarcasm Handling**

* If sarcasm score > 0.60 and total score < 0.40 → Classified as *Harmless Sarcasm*
* If sarcasm score > 0.60 and total score ≥ 0.40 → Classified as *Sarcastic Bullying*

---

## **Project Structure**

```
cyber_chat_ai/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   └── message_model.dart
│   ├── services/
│   │   ├── supabase_service.dart
│   │   ├── ai_service.dart
│   │   └── email_service.dart
│   └── screens/
│       ├── auth/
│       │   └── login_screen.dart
│       ├── chat/
│       │   ├── chat_screen.dart
│       │   ├── users_list_screen.dart
│       │   └── widgets/
│       │       ├── message_bubble.dart
│       │       └── message_input.dart
│       └── admin/
│           └── admin_dashboard.dart
├── android/
└── pubspec.yaml
```

---

## **Database Schema**

### **Users Table**

* id (UUID, primary key)
* username (unique)
* password
* email
* alert_shown (boolean)
* is_blocked (boolean)
* warning_count (integer)
* created_at

---

### **Messages Table**

* id
* sender_id
* receiver_id
* text
* image_url
* flagged
* bully_score
* sarcasm_type
* prediction
* created_at

---

### **Flags Table**

* id
* user_id
* username
* message_id
* message_text
* bully_score
* sarcasm_type
* prediction
* warning_count
* severity
* action
* admin_report
* mail_sent
* notified
* created_at

---

## **Setup Instructions**

1. Clone the repository:

```
git clone https://github.com/Dharsh-04/cyber_chat_ai.git
cd cyber_chat_ai
```

2. Configure credentials in `main.dart`:

```
supabaseUrl
supabaseAnonKey
ngrokApiUrl
geminiApiKey
```

3. Configure Groq API key in `ai_service.dart`

4. Configure email credentials in `email_service.dart`

5. Run the project:

```
flutter pub get
flutter run
```

---

## **AI Inference Server**

### **Endpoints**

* `GET /health` — Health check
* `POST /predict/text` — Text classification
* `POST /predict/multimodal` — Image + caption analysis

---

## **Admin Credentials**

* Username: admin
* Password: admin@safechat123

---

## **Limitations and Future Improvements**

* Current model supports English only
* Passwords are stored in plain text (should use hashing in production)
* HuggingFace free tier may limit performance under load
* SMTP requires Gmail App Password setup
* No group chat support currently
* Latency depends on external LLM (Groq API) response time

