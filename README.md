# 👤 Face Recognition System

**Kompletny system rozpoznawania twarzy z wieloma klientami**

---

## 🚀 Quick Start

```bash
# 1. Backend
cd backend
npm install
pip3 install --break-system-packages deepface tf-keras tensorflow==2.20.0 opencv-python
node server.js

# 2. Web
cd frontend-web
python3 -m http.server 8080

# 3. Desktop
cd frontend-web
pip3 install --break-system-packages PyQt6 requests
python3 main.py
```

**📘 Szczegóły:** [QUICK_START.md](./QUICK_START.md)

---

## 📖 Dokumentacja

| Dokument | Opis |
|----------|------|
| [QUICK_START.md](./QUICK_START.md) | ⚡ Start w 5 minut |
| [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) | 📖 Kompletny przewodnik wdrożenia |
| [NETWORK_SETUP.md](./NETWORK_SETUP.md) | 🌐 Multi-device setup |
| [TEAM_AI_GUIDE.md](./TEAM_AI_GUIDE.md) | 👥 API kontrakt |

---

## 🎯 Architektura

```
Backend (Express.js + DeepFace)
         ↓  REST API
    ┌────┴────┬─────────┬────────┐
    │         │         │        │
  Web      Desktop   Android    iOS
 HTML5     PyQt6      MAUI      MAUI
```

---

## 🔧 Tech Stack

- **Backend:** Node.js + Express + Python + DeepFace (Facenet512)
- **Web:** HTML5 + Vanilla JS
- **Desktop:** PyQt6
- **Mobile:** .NET MAUI (C#)
- **Database:** SQLite
- **ML:** Cosine Similarity

---

## 🎬 Demo

### Laptop Demo (3 min setup)
```bash
cd backend && node server.js &
cd frontend-web && python3 main.py
```

### Multi-Device Demo (10 min setup)
Zobacz [NETWORK_SETUP.md](./NETWORK_SETUP.md)

---

**Gotowe do startu?** 🚀 Zobacz [QUICK_START.md](./QUICK_START.md)!
