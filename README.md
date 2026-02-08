# Mitran – Advanced Stray Dog Intelligence & Guardian Network (Web)

Mitran is an AI-powered, community-driven platform designed to address stray dog welfare challenges in the Delhi-NCR region.

This repository contains the **Flutter-based Web frontend** for the Mitran ecosystem.

The platform enables citizens, volunteers, and NGOs to collaboratively identify, monitor, and assist stray dogs through a unified digital ecosystem.

## Project Vision

Delhi-NCR faces a growing stray dog challenge, leading to public safety concerns, welfare issues, and divided public opinion.
Mitran aims to bridge this gap by introducing **data transparency, AI-driven assistance, and real-time coordination** —benefiting both humans and animals.

## ✨ Key Features

- **Community Hub**: Real-time posts, updates, and coordination among volunteers.
- **Dog Directory (Mitran Records)**:
  - Browse stray dogs available for adoption.
  - View sterilization & vaccination status.
  - Filter by location and health status.
- **AI Integrations (Fully Implemented)**:
  - **Behavioral Guidance Chatbot**: AI assistant for dog behavior queries.
  - **Disease Detection**: Image-based AI analysis for identifying skin diseases in stray dogs.
- **User Profiles**: Manage your contributions and view your activity.
- **Secure Authentication**: Integrated with Firebase (Google Sign-In & Email/Password).

## 🛠️ Tech Stack

- **Frontend Framework**: Flutter Web
- **State Management**: Riverpod
- **Backend Services**: Firebase (Auth, Cloud Firestore, Storage)
- **AI Services**:
  - Python Backend (FastAPI / Flask) hosted on Render.
  - Integrated via REST APIs for Chatbot and Disease Detection.

## 🧪 Current Status

**🚧 Under Active Development**

This project is part of an academic **Minor Project** and is continuously evolving with new features and UI improvements.

## 📜 Related Policy Context

Mitran aligns with the objectives of the **Animal Birth Control (ABC) Rules, 2023**, focusing on:
- Sterilization & vaccination tracking
- Humane management of stray dogs
- Data-driven welfare and coordination

## 👥 Contributors

- **Jay Tomar**
- **Deekshant Tilwani**

## 📌 Note

This repository contains **only the frontend (Flutter Web app)**.
Backend services, AI models, and APIs are maintained in separate repositories.

## Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run Locally**:
   ```bash
   flutter run -d chrome
   ```

3. **Build for Web**:
   ```bash
   flutter build web
   ```
