# Akhil Bhartiya Rander Parivar Samaj (abrp)

A modular, robust monorepo setup hosting the backend server and mobile application components for the **Akhil Bhartiya Rander Parivar Samaj** community platform.

---

## System Architecture Overview

* **Backend API (`/backend`)**: Hono.js runtime, configured to deploy as a Serverless/Edge function on Vercel. Connects to a serverless **Neon PostgreSQL** database using **Drizzle ORM**.
* **Mobile Client (`/mobile_app`)**: Native **Flutter** application targeting Android and iOS, implementing clean feature-first architecture, **Riverpod** state management, and **GoRouter** role-based routing.
* **Storage (`Cloudflare R2`)**: Images and assets are uploaded directly from the mobile app to Cloudflare R2 using pre-signed PUT URLs generated dynamically by the Hono API, bypassing Vercel payload limit restrictions.
* **Notifications**: Integrated Firebase Cloud Messaging (FCM) to trigger background notification alerts.
* **Emails**: Brevo REST API endpoints for SMTP transactional email dispatches.

---

## Getting Started

### 1. Backend Setup

First, configure your environment variables:
1. Copy or edit the `/backend/.env` file.
2. Replace placeholders with actual credentials (Neon DB link, Cloudflare R2 tokens, Google Client IDs, Firebase and Brevo tokens).

#### Local Docker Development
Local development is coordinated using the shared Docker setup.
From the `/home/shivam/work/shared-docker/` directory, launch the orchestrator:
```bash
docker compose up -d --build
```
This will:
* Boot Traefik Proxy.
* Setup a local Postgres database container named `abrp_db` automatically.
* Launch the `abrp-backend` service in watcher mode (reloads instantly upon file changes) bound to port `8005`.

Access the health check endpoint locally at: [http://localhost:8005/](http://localhost:8005/) or [http://abrp-api.localhost/](http://abrp-api.localhost/)

#### Running Database Migrations
Generate and push database changes securely:
```bash
cd backend
pnpm run db:generate    # Generates Drizzle migration files based on schema.ts
pnpm run db:migrate     # Executes migration and applies tables directly to database
```

---

### 2. Flutter Mobile Application Setup

The Flutter application targets Android and iOS with Hindi and English localization support.

#### Adding Platform Configurations
1. **Android**: Place your Firebase configuration `google-services.json` inside `/mobile_app/android/app/`.
2. **iOS**: Place `GoogleService-Info.plist` inside `/mobile_app/ios/Runner/`.

#### Running the App
To run the Flutter app on a connected emulator or device:
```bash
cd mobile_app
flutter run
```

#### Re-Running Code Generators (if schemas/providers change)
To rebuild the Riverpod annotation states:
```bash
cd mobile_app
dart run build_runner build --delete-conflicting-outputs
```

---

## Directory Structure Map

```
abrp/
├── backend/                       # Hono.js API (Targeted for Vercel Serverless)
│   ├── src/
│   │   ├── index.ts               # API Entry Point (Vercel handler wrapper)
│   │   ├── db/                    # Drizzle ORM schemas and Neon connection client
│   │   ├── middleware/            # JWT authorization, logging, and role guards
│   │   ├── routes/                # API Route Handlers (auth, upload, notifications, users)
│   │   └── services/              # Third-party integrations (Brevo, FCM, Cloudflare R2)
│   ├── vercel.json                # Vercel Deployment settings
│   └── Dockerfile                 # Local Docker deployment container
│
├── mobile_app/                    # Flutter Mobile Application (Android & iOS)
│   ├── lib/
│   │   ├── main.dart              # App bootstrapping
│   │   ├── app.dart               # Theme and Router wrapper
│   │   ├── core/                  # Core modules (constants, network, routing, localization)
│   │   └── features/              # Feature modules (auth, profile, home, admin, notifications)
│   └── pubspec.yaml
│
└── README.md                      # Developer guide
```
