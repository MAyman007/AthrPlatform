# Athr (أثر)

**Athr is a modern, actionable threat intelligence platform designed for organizations.**

It monitors external data leaks, compromised credentials, and active threat sources. Unlike other tools that just report data, Athr is built to be simple enough for non-technical team members to understand the risk, yet powerful enough for security experts to take immediate, decisive action.

## ✨ Core Value Proposition

Athr is designed to bridge the gap between data and action. Our philosophy is: **"Simplicity for the non-expert, depth for the expert."**

We don't just show you that a leak occurred. We provide a full, contextual picture that includes:

* **What was leaked:** Credentials, database dumps, source code, etc.
* **Where it was found:** Dark web forums, GitHub, Telegram channels, etc.
* **How it was leaked:** We link external leaks to specific, compromised internal assets (machines, user accounts) by analyzing malware logs.
* **What to do now:** Every incident is paired with a prioritized, step-by-step checklist of "Recommended Actions" to guide your remediation.

## 🚀 Core Features

* **High-Level Dashboard:** A single pane of glass showing your organization's key security metrics, including KPIs, incidents by severity, and top leak sources.
* **Compromised Asset Guardian:** A dedicated view to track and manage internal machines that have been identified in malware logs.
* **Alerts Feed:** A real-time notification center for all new, unread threats.
* **Incident Management:** A full-featured triage and investigation page to manage the lifecycle of an incident from "New" to "Resolved."
* **Contextual Recommendations:** A dynamic engine that provides a prioritized, step-by-step action plan for every specific incident.
* **Asset-Based Search (Threat Hunting):** A powerful search feature that allows security teams to actively hunt for threats across our global database using their known assets (domains, IPs, keywords).

## 💻 Technology Stack

This project uses a modern, hybrid architecture to ensure security, scalability, and real-time performance.

### Frontend (Client: `athr_app`)

* **Framework:** Flutter Web
* **State Management:** Provider (following an MVVM pattern)
* **Routing:** `go_router`
* **Data Visualization:** `fl_chart`

### Backend (Main Platform: `athr_platform`)

* **Authentication:** Firebase Authentication (secured with App Check)
* **Database (Customer Vault):** Firestore (secured with comprehensive Security Rules)
* **Security:** Firebase App Check with reCAPTCHA v3 (to protect all services)

### Backend (Microservice: [`athr_backend_api`](https://github.com/0xVirtu4l/Athr_Source/tree/main/Web-APIs))

This is a separate, high-performance backend for specialized tasks.

* **Framework:** FastAPI (Python)
* **Database (Global Threat DB):** `aiosqlite` (interfacing with a large SQLite database)
* **Performance:** Fully asynchronous with `async/await`, `httpx`, and `uvicorn`.
* **Security:** Rate limiting (`slowapi`) and custom API key verification.
* **Deployment:** Designed to run on a private VPS.

## 🔒 Infrastructure & Security

We use Cloudflare across the platform to improve performance and protect our infrastructure. Key details:

* **CDN & Reverse Proxy:** We use Cloudflare to manage our DNS, act as a high-performance reverse proxy, and cache static assets.
* **DDoS Protection & WAF:** All platform traffic is filtered through Cloudflare's security-first global network, providing enterprise-grade DDoS mitigation and a Web Application Firewall (WAF) that protects against common web exploits.
* **Origin Server Protection:** Our private VPS origin IP address is hidden. We configure Cloudflare's firewall rules to ensure the backend accepts traffic only from Cloudflare's official IP ranges, preventing direct scans or attacks against the origin.
* **SSL/TLS:** Cloudflare manages our SSL certificates and enforces HTTPS-only connections so that all communication between users and the platform is encrypted.

## 🏁 Getting Started

To get the project running locally, you will need to set up both the Flutter frontend and the FastAPI backend.

### Prerequisites

* Flutter SDK (v3.x.x or higher)
* Python 3.9+
* A Firebase project
* An IPinfo.io account (for the IP checking microservice)

### 1. Frontend Setup (`athr_app`)

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/MAyman007/athr-website.git
    cd athr-website/app_source
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure Firebase:**
    * Run the FlutterFire CLI to configure your app: `flutterfire configure`
    * This will generate your `lib/firebase_options.dart` file.
4.  **Configure App Check (Critical):**
    * Go to the Firebase Console -> App Check and register your web app.
    * Get your reCAPTCHA v3 site key.
    * Paste the key into `web/index.html` and `lib/main.dart`.
    * Go to the Google Cloud Console -> reCAPTCHA Enterprise and **add `localhost`** to the list of allowed domains.
5.  **Run the App:**
    ```bash
    flutter run -d chrome
    ```

### 2. Backend Setup ([`athr_backend_api`](https://github.com/0xVirtu4l/Athr_Source/tree/main/Web-APIs))

This server is required for features like the VPN/Proxy check.

1.  **Navigate to the backend directory:**
    ```bash
    cd Web-APIs
    ```
2.  **Create a virtual environment and install dependencies:**
    ```bash
    python -m venv venv
    source venv/bin/activate  # (or .\venv\Scripts\activate on Windows)
    pip install -r requirements.txt
    ```
3.  **Set Environment Variables in `.env`:**
    You must set these for the server to run.
    ```bash
    IPINFO_API_KEY="your_ipinfo.io_api_key"
    YOUR_APP_SECRET_KEY="generate_a_long_random_string_here"
    ```
4.  **Add Service Account Key:**
    * Go to your Firebase project settings -> Service Accounts.
    * Generate a new private key and download the JSON file.
    * Place the file in this directory and rename it to `firebase-service-account-key.json`.
5.  **Run the Backend Server:**
    ```bash
    python main.py
    ```
    The API server will now be running on `http://0.0.0.0:8000`.

## 🗺️ Future Roadmap

This project is in active development. Key features on our roadmap include:

* **Admin Dashboard:** A separate, secure application for platform owners to manage users, organizations, and the recommendations database.
* **Public API:** A full-featured, billed API for customers to programmatically access their data and integrate with their own tools (e.g., SIEM, Slack).
* **Automated Threat Ingestion:** Moving the search logic to a recurring background job that automatically finds and ingests new threats into the Customer Data Vault.
* **Full Localization:** Complete Arabic (ar) language support across the entire platform.
