# ⚡ Quick Start - Face Recognition System

## 5 minut do działającego systemu!

### Wymagania
- Node.js 16+
- Python 3.9-3.11 (**NIE 3.12!**)
- 4GB RAM

---

## 🚀 Start Backend (2 min)

```bash
# 1. Dependencies
cd backend
npm install
pip3 install --break-system-packages deepface tf-keras tensorflow==2.20.0 opencv-python

# 2. Config
echo "PORT=8000
DB_PATH=./db/faces.db
MATCH_THRESHOLD=0.4
PYTHON_PATH=python3" > .env

# 3. RUN!
node server.js

# Powinieneś zobaczyć:
# Server running on http://0.0.0.0:8000
# Match threshold: 0.4
```

✅ Test: `curl http://localhost:8000/api/health` → `{"status":"ok"}`

---

## 🌐 Start Web Frontend (30 sek)

```bash
# Nowe okno terminala
cd frontend-web

# Sprawdź config
cat config.json  # Powinno być: http://localhost:8000/api

# RUN!
python3 -m http.server 8080

# Otwórz: http://localhost:8080
```

✅ Test: Wybierz zdjęcie → Rozpoznaj

---

## 🖥️ Start Desktop App (30 sek)

```bash
# Nowe okno terminala
cd frontend-web

# Install (jeśli nie masz)
pip3 install --break-system-packages PyQt6 requests

# RUN!
python3 main.py
```

✅ Test: Kliknij "Wybierz Zdjęcie" → wybierz plik

---

## 📱 Start Mobile App (Visual Studio)

```bash
# 1. Otwórz projekt
cd mobile
# Otwórz FaceScaner.slnx w Visual Studio 2022

# 2. Edytuj appsettings.json
{
  "ApiBaseUrl": "http://10.0.2.2:8000/api"  // Dla Android Emulator
}

# 3. W Visual Studio:
# - Wybierz "Android Emulator" z dropdown
# - Kliknij Play (F5)
```

✅ Test: Kliknij "Zrób Zdjęcie" lub "Wybierz z Galerii"

---

## 📊 Import Danych Testowych

```bash
# Backend już działa, więc w nowym terminalu:
cd backend
node import_dataset.js --path ./SmallDataset

# Powinieneś zobaczyć:
# Processing Akshay Kumar (3 images)...
# Processing Alexandra Daddario (3 images)...
# Processing Alia Bhatt (3 images)...
# === Import Complete ===
```

**Testowy dataset w SmallDataset/:**
- Akshay Kumar (3 zdjęcia)
- Alexandra Daddario (3 zdjęcia)  
- Alia Bhatt (3 zdjęcia)

---

## 🎯 Szybki Test End-to-End

1. **Backend działa?** → `curl http://localhost:8000/api/health`
2. **Dataset zaimportowany?** → `node verify_db.js` (powinno pokazać 3 osoby)
3. **Web działa?** → Otwórz localhost:8080 → wybierz `backend/test_face.jpg`
4. **Desktop działa?** → `python3 main.py` → wybierz zdjęcie
5. **Mobile działa?** → Zrób selfie w emulatorze

---

## ❗ Najczęstsze Problemy

### "Cannot connect to backend"
```bash
# Sprawdź czy backend działa:
curl http://localhost:8000/api/health

# Jeśli nie - uruchom:
cd backend && node server.js
```

### "Python script failed" / "DeepFace error"
```bash
# Sprawdź wersję Pythona (MUSI BYĆ 3.9-3.11)
python3 --version

# Reinstall
pip3 uninstall tensorflow tf-keras deepface
pip3 install --break-system-packages tensorflow==2.20.0 tf-keras deepface
```

### "Port 8000 already in use"
```bash
# Znajdź proces
lsof -i :8000  # Mac/Linux
netstat -ano | findstr :8000  # Windows

# Zabij go
kill -9 <PID>
```

### Mobile: "Connection refused"
```json
// Edytuj mobile/appsettings.json:

// Android Emulator:
{ "ApiBaseUrl": "http://10.0.2.2:8000/api" }

// Fizyczne urządzenie (znajdź IP komputera przez ifconfig/ipconfig):
{ "ApiBaseUrl": "http://192.168.1.100:8000/api" }
```

---

## 📂 Struktura Projektu

```
Face-Recognition-Project/
├── backend/              # Express.js + Python DeepFace
│   ├── server.js        # Main server
│   ├── face_service.py  # DeepFace integration
│   ├── db/faces.db      # SQLite database
│   └── SmallDataset/    # Testowe zdjęcia
├── frontend-web/         # Web + Desktop
│   ├── index.html       # Web app (HTML5)
│   └── main.py          # Desktop app (PyQt6)
├── mobile/               # MAUI (Android/iOS)
│   ├── Services/        # API client
│   ├── ViewModels/      # MVVM
│   └── Views/           # UI
└── DEPLOYMENT_GUIDE.md   # Pełna dokumentacja
```

---

## 🎬 Demo Flow

### Scenariusz: Laptop Demo
```bash
# Terminal 1
cd backend && node server.js

# Terminal 2
cd backend && node import_dataset.js --path ./SmallDataset

# Terminal 3
cd frontend-web && python3 main.py

# Demo:
# 1. Wybierz backend/SmallDataset/Akshay Kumar/Akshay Kumar_0.jpg
# 2. Pokaż wynik: "Akshay Kumar" z confidence ~95%
# 3. Wybierz Alexandra Daddario
# 4. Wybierz Alia Bhatt
# 5. Wybierz losowe zdjęcie (nie w bazie) → "Nie rozpoznano"
```

---

## 🔗 Linki

- **Pełna dokumentacja**: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
- **API Kontrakt**: [TEAM_AI_GUIDE.md](./TEAM_AI_GUIDE.md)
- **Backend Commands**: [backend/COMMANDS_CHEATSHEET.md](./backend/COMMANDS_CHEATSHEET.md)
- **Dataset Kaggle**: https://www.kaggle.com/datasets/vasukipatel/face-recognition-dataset/data

---

## ✅ Checklist

- [ ] Backend: `curl http://localhost:8000/api/health` → OK
- [ ] Dataset: `node verify_db.js` → pokazuje osoby
- [ ] Web: http://localhost:8080 → strona ładuje się
- [ ] Desktop: `python3 main.py` → okno się otwiera
- [ ] Mobile: APK zainstalowany i łączy się z API

---

## 🆘 Stuck?

1. Sprawdź logi serwera (terminal gdzie jest `node server.js`)
2. Sprawdź Browser Console (F12) dla web
3. Uruchom testy: `cd backend/testy sh && ./run_all_tests.sh`
4. Zobacz [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) → sekcja "Rozwiązywanie Problemów"

---

**Wszystko działa?** 🎉 Gratulacje! Masz w pełni działający system rozpoznawania twarzy!
