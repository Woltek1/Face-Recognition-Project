# 🚀 Face Recognition System - Kompletny Przewodnik Wdrożenia

## 📋 Spis Treści
1. [Przegląd Systemu](#przegląd-systemu)
2. [Wymagania Systemowe](#wymagania-systemowe)
3. [Instalacja Backend](#instalacja-backend)
4. [Instalacja Frontend Web](#instalacja-frontend-web)
5. [Instalacja Desktop (PyQt6)](#instalacja-desktop-pyqt6)
6. [Instalacja Mobile (MAUI)](#instalacja-mobile-maui)
7. [Przygotowanie Urządzenia Demo](#przygotowanie-urządzenia-demo)
8. [Rozwiązywanie Problemów](#rozwiązywanie-problemów)

---

## 🎯 Przegląd Systemu

System składa się z 4 komponentów:

```
┌─────────────────────────────────────────────┐
│          Backend (Express.js + Python)       │
│     REST API + DeepFace (Facenet512)        │
│         Port: 8000 (HTTP REST)              │
└──────────────┬──────────────────────────────┘
               │
    ┌──────────┼──────────┬──────────────┐
    │          │          │              │
┌───▼───┐  ┌──▼───┐  ┌───▼────┐  ┌─────▼─────┐
│  Web  │  │Desktop│  │ Mobile │  │  Mobile   │
│ HTML5 │  │ PyQt6 │  │Android │  │    iOS    │
└───────┘  └───────┘  └────────┘  └───────────┘
```

**Przepływ danych:**
1. Klient wysyła zdjęcie → POST /api/recognize
2. Backend wywołuje Python (DeepFace) → Ekstrakcja embeddings
3. Backend porównuje z bazą (SQLite) → Cosine similarity
4. Zwrot JSON → { matched, person, confidence }

---

## 💻 Wymagania Systemowe

### Backend
- **Node.js**: 16+ (zalecane: 20.x)
- **Python**: 3.9 - 3.11 (WAŻNE: 3.12+ nie wspiera tensorflow 2.20)
- **RAM**: minimum 4GB (zalecane 8GB dla DeepFace)
- **Dysk**: 2GB wolnego miejsca (modele ML)

### Desktop (PyQt6)
- **Python**: 3.9+
- **PyQt6**: 6.x
- **System**: Windows, macOS, Linux

### Mobile (MAUI)
- **Android**: Android 7.0+ (API 24+)
- **iOS**: iOS 14.0+
- **Narzędzia**: Visual Studio 2022 lub Visual Studio Code z .NET MAUI

### Web
- Dowolna przeglądarka (Chrome, Firefox, Safari, Edge)

---

## 🔧 Instalacja Backend

### Krok 1: Instalacja Node.js Dependencies

```bash
cd backend

# Instalacja pakietów Node.js
npm install

# Weryfikacja
npm list | grep express
# Powinno pokazać: express@4.x.x
```

**Zainstalowane pakiety:**
- `express` - serwer HTTP
- `cors` - CORS dla wszystkich klientów
- `multer` - upload plików
- `better-sqlite3` - baza danych
- `dotenv` - zmienne środowiskowe

### Krok 2: Instalacja Python Dependencies

**macOS (zalecane dla M1/M2):**
```bash
# WAŻNE: Użyj Python 3.11, NIE 3.12!
python3 --version  # Sprawdź wersję

# Instalacja
pip3 install --break-system-packages deepface tf-keras tensorflow==2.20.0 opencv-python

# Weryfikacja
python3 -c "from deepface import DeepFace; print('OK')"
```

**Windows:**
```bash
# Python 3.9-3.11
pip install deepface tf-keras tensorflow opencv-python
```

**Linux:**
```bash
pip3 install deepface tf-keras tensorflow opencv-python
```

### Krok 3: Konfiguracja .env

```bash
# Stwórz plik .env
cat > .env << EOF
PORT=8000
DB_PATH=./db/faces.db
MATCH_THRESHOLD=0.4
PYTHON_PATH=python3
EOF
```

**Parametry:**
- `PORT` - port serwera (domyślnie 8000)
- `DB_PATH` - ścieżka do bazy SQLite
- `MATCH_THRESHOLD` - próg podobieństwa (0.4 = 60% confidence)
- `PYTHON_PATH` - ścieżka do Pythona (`python3` na Mac/Linux, `python` na Windows)

### Krok 4: Test Backend

```bash
# Uruchom serwer
node server.js

# Powinno pokazać:
# Server running on http://0.0.0.0:8000
# Match threshold: 0.4
```

**Test health endpoint:**
```bash
curl http://localhost:8000/api/health

# Odpowiedź: {"status":"ok"}
```

### Krok 5: Import Dataset (Opcjonalnie)

Jeśli masz dataset w formacie:
```
dataset/
├── Person1/
│   ├── face1.jpg
│   └── face2.jpg
└── Person2/
    └── face1.jpg
```

Importuj:
```bash
node import_dataset.js --path ./SmallDataset

# Lub z dowolnej ścieżki:
node import_dataset.js --path ~/Downloads/face-dataset
```

**Dataset Kaggle (opcjonalnie):**
https://www.kaggle.com/datasets/vasukipatel/face-recognition-dataset/data

---

## 🌐 Instalacja Frontend Web

### Krok 1: Konfiguracja

```bash
cd frontend-web

# Sprawdź config.json
cat config.json
```

**Edytuj `config.json` jeśli potrzeba:**
```json
{
  "api_url": "http://localhost:8000/api"
}
```

### Krok 2: Uruchomienie

**Opcja A - Prosty serwer Python:**
```bash
# Python 3
python3 -m http.server 8080

# Otwórz: http://localhost:8080
```

**Opcja B - Live Server (VS Code):**
1. Zainstaluj rozszerzenie "Live Server"
2. Kliknij prawym na `index.html`
3. "Open with Live Server"

**Opcja C - Node.js http-server:**
```bash
npx http-server -p 8080

# Otwórz: http://localhost:8080
```

### Krok 3: Test Web App

1. Otwórz http://localhost:8080
2. Powinieneś zobaczyć: "System Rozpoznawania Twarzy"
3. Kliknij "Wybierz Zdjęcie" → wybierz zdjęcie twarzy
4. Kliknij "Rozpoznaj"
5. Sprawdź wynik

---

## 🖥️ Instalacja Desktop (PyQt6)

### Krok 1: Instalacja Dependencies

```bash
cd frontend-web  # Desktop app jest tutaj (main.py)

# Instalacja PyQt6
pip3 install --break-system-packages PyQt6 requests

# Lub bez --break-system-packages:
pip3 install PyQt6 requests
```

### Krok 2: Konfiguracja

Sprawdź `config.json`:
```json
{
  "api_url": "http://localhost:8000/api"
}
```

### Krok 3: Uruchomienie

```bash
python3 main.py
```

**Pierwsze uruchomienie:**
- Okno pojawi się w ciemnym motywie
- Przyciski: "Wybierz Zdjęcie" i "Wyczyść"
- Kliknij "Wybierz Zdjęcie" → wybierz plik
- Aplikacja automatycznie wyśle do API

### Troubleshooting Desktop

**Problem: "No module named 'PyQt6'"**
```bash
# Sprawdź instalację
pip3 list | grep PyQt6

# Reinstall
pip3 uninstall PyQt6
pip3 install PyQt6
```

**Problem: "Cannot connect to server"**
- Sprawdź czy backend działa: `curl http://localhost:8000/api/health`
- Sprawdź `config.json` - czy URL się zgadza
- Sprawdź firewall

---

## 📱 Instalacja Mobile (MAUI)

### Wymagania

**Visual Studio 2022:**
- Workload: ".NET Multi-platform App UI development"
- Android SDK (dla Android)
- Xcode (dla iOS - tylko macOS)

**Visual Studio Code (alternatywa):**
```bash
# Zainstaluj .NET MAUI workload
dotnet workload install maui
```

### Krok 1: Otwórz Projekt

```bash
cd mobile

# Visual Studio 2022:
# Otwórz FaceScaner.slnx

# VS Code:
code .
```

### Krok 2: Konfiguracja API

Edytuj `appsettings.json`:
```json
{
  "ApiBaseUrl": "http://10.0.2.2:8000/api"
}
```

**IP dla emulatorów:**
- **Android Emulator**: `10.0.2.2` (alias dla localhost hosta)
- **iOS Simulator**: `localhost` lub IP komputera w sieci lokalnej
- **Fizyczne urządzenie**: IP komputera w tej samej sieci Wi-Fi (np. `192.168.1.100:8000`)

### Krok 3: Build i Deploy

**Android (Emulator):**
```bash
# W Visual Studio 2022:
# 1. Wybierz "Android Emulator" z dropdown
# 2. Kliknij "Play" (F5)

# Lub CLI:
dotnet build -f net10.0-android
dotnet run -f net10.0-android
```

**Android (Fizyczne urządzenie):**
1. Włącz "Developer Options" na telefonie
2. Włącz "USB Debugging"
3. Podłącz USB
4. W Visual Studio wybierz swoje urządzenie
5. Kliknij "Play"

**iOS (Simulator - tylko macOS):**
```bash
dotnet build -f net10.0-ios
dotnet run -f net10.0-ios
```

### Krok 4: Instalacja APK (Android)

**Opcja A - APK z bin/Debug:**
```bash
# Znajdź APK
ls bin/Debug/net10.0-android/*.apk

# Transfer przez USB
adb install bin/Debug/net10.0-android/com.companyname.facescaner-Signed.apk
```

**Opcja B - Build Release:**
```bash
dotnet publish -f net10.0-android -c Release

# APK będzie w:
# bin/Release/net10.0-android/publish/
```

### Troubleshooting Mobile

**Problem: "Unable to connect to API"**

1. **Sprawdź backend:**
```bash
curl http://localhost:8000/api/health
```

2. **Emulator Android - użyj 10.0.2.2:**
```json
{ "ApiBaseUrl": "http://10.0.2.2:8000/api" }
```

3. **Fizyczne urządzenie - użyj IP w sieci:**
```bash
# Znajdź IP komputera
ipconfig  # Windows
ifconfig  # Mac/Linux

# Użyj tego IP:
{ "ApiBaseUrl": "http://192.168.1.100:8000/api" }
```

4. **Sprawdź firewall** - upewnij się, że port 8000 jest otwarty

**Problem: "Camera permission denied"**
- Android: Dodano `CAMERA` permission w `AndroidManifest.xml`
- iOS: Dodano `NSCameraUsageDescription` w `Info.plist`

---

## 🎬 Przygotowanie Urządzenia Demo

### Scenariusz 1: Laptop (Wszystko w jednym)

**Co potrzebujesz:**
- Laptop z Windows/macOS/Linux
- Kamera (wbudowana lub USB)
- Dataset ze zdjęciami (SmallDataset lub Kaggle)

**Setup:**
```bash
# 1. Uruchom backend
cd backend
node server.js &

# 2. Import dataset
node import_dataset.js --path ./SmallDataset

# 3. Uruchom desktop app
cd ../frontend-web
python3 main.py
```

**Demo:**
1. Przygotuj zdjęcia testowe (Alexandra Daddario, Akshay Kumar, Alia Bhatt)
2. W aplikacji desktop: "Wybierz Zdjęcie"
3. Pokaż wynik rozpoznawania
4. Powtórz dla różnych osób

---

### Scenariusz 2: Demo Web (Laptop + Projektor)

**Setup:**
```bash
# 1. Backend
cd backend
node server.js &

# 2. Frontend web
cd ../frontend-web
python3 -m http.server 8080 &

# 3. Otwórz w przeglądarce
open http://localhost:8080
```

**Demo:**
1. Pokaż interfejs w trybie pełnoekranowym (F11)
2. Przeciągnij zdjęcie (drag & drop)
3. Pokaż animacje rozpoznawania
4. Pokaż szczegóły (pewność, czas)

---

### Scenariusz 3: Demo Mobile (Telefon + Komputer)

**Wymagania:**
- Telefon Android/iOS
- Komputer z backendem
- Ta sama sieć Wi-Fi

**Setup:**
```bash
# 1. Znajdź IP komputera
ipconfig  # Windows: szukaj "IPv4 Address"
ifconfig  # Mac: szukaj "inet" w en0

# Przykład: 192.168.1.100

# 2. Edytuj mobile/appsettings.json
{
  "ApiBaseUrl": "http://192.168.1.100:8000/api"
}

# 3. Build i install na telefon
dotnet publish -f net10.0-android -c Release

# 4. Uruchom backend
cd backend
node server.js
```

**Demo:**
1. Otwórz aplikację na telefonie
2. Kliknij "Zrób Zdjęcie" (selfie)
3. Lub "Wybierz z Galerii"
4. Pokaż wynik na telefonie
5. Pokaż historię skanów

---

### Scenariusz 4: Multi-client Demo

**Wymagania:**
- 1 komputer z backendem
- 1 laptop z web frontend
- 1 telefon z mobile app
- Router Wi-Fi

**Setup:**
```bash
# Komputer 1 (Backend):
cd backend
node server.js
# IP: 192.168.1.100

# Laptop (Web):
# Edytuj frontend-web/config.json:
{ "api_url": "http://192.168.1.100:8000/api" }
python3 -m http.server 8080

# Telefon (Mobile):
# Edytuj appsettings.json:
{ "ApiBaseUrl": "http://192.168.1.100:8000/api" }
```

**Demo:**
1. Jednocześnie otwórz web + mobile
2. Wyślij zdjęcie z web
3. Wyślij to samo zdjęcie z mobile
4. Pokaż że wyniki są identyczne
5. Pokaż że oba klienty działają równolegle

---

## 🔧 Rozwiązywanie Problemów

### Backend

**Problem: "Python script failed"**
```bash
# Test ręczny
cd backend
python3 face_service.py --image test_face.jpg --mode extract

# Jeśli błąd z tensorflow:
pip3 uninstall tensorflow tf-keras
pip3 install tensorflow==2.20.0 tf-keras
```

**Problem: "Database locked"**
```bash
# Sprawdź procesy
lsof db/faces.db

# Usuń lock (UWAGA: tylko jeśli serwer nie działa!)
rm db/faces.db-*

# Restart
node server.js
```

**Problem: "Port 8000 already in use"**
```bash
# Znajdź proces
lsof -i :8000  # Mac/Linux
netstat -ano | findstr :8000  # Windows

# Zabij proces
kill -9 <PID>

# Lub zmień port w .env
PORT=8001
```

---

### Frontend Web

**Problem: "CORS error"**
- Sprawdź czy backend ma CORS enabled (powinien być defaultowo)
- Sprawdź console w przeglądarce (F12)
- Upewnij się że URL w config.json jest poprawny

**Problem: "Cannot read response"**
- Sprawdź Network tab (F12)
- Zobacz czy request idzie do właściwego URL
- Sprawdź czy backend zwraca JSON

---

### Desktop PyQt6

**Problem: "QApplication: invalid style override"**
- Ignoruj - to warning, nie error
- Aplikacja powinna działać

**Problem: "Failed to load image"**
- Sprawdź czy wybierasz plik .jpg, .jpeg, .png
- Sprawdź czy plik nie jest uszkodzony
- Sprawdź konsole (-c flag przy uruchomieniu)

---

### Mobile MAUI

**Problem: "HttpRequestException: Connection refused"**

1. **Sprawdź IP:**
```bash
# Android emulator MUSI używać 10.0.2.2
{ "ApiBaseUrl": "http://10.0.2.2:8000/api" }

# Fizyczne urządzenie MUSI używać IP w sieci
{ "ApiBaseUrl": "http://192.168.1.100:8000/api" }
```

2. **Ping test z telefonu:**
- Zainstaluj "Network Utilities" z Play Store
- Ping do IP komputera
- Jeśli nie działa - problem z siecią/firewall

3. **Firewall:**
```bash
# Windows - dodaj regułę dla portu 8000
# macOS:
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add node

# Linux:
sudo ufw allow 8000
```

**Problem: "Build failed"**
```bash
# Clean solution
dotnet clean
rm -rf bin obj

# Restore
dotnet restore

# Rebuild
dotnet build
```

---

## 📊 Metryki Wydajności

**Backend (single request):**
- Import zdjęcia: ~50ms
- DeepFace extraction: ~2-5s (pierwsze użycie: ~10s z cache)
- Database query: ~5-20ms
- **Total: ~2-6s**

**Optymalizacja:**
- Pierwsze żądanie: ~10s (ładowanie modelu)
- Kolejne żądania: ~2-3s (model w cache)

**Dataset size recommendations:**
- Testowy: 3-10 osób × 2-3 zdjęcia = ~30 embeddings
- Demo: 10-50 osób × 3-5 zdjęć = ~250 embeddings
- Produkcja: Do 10,000 embeddings (SQLite limit)

---

## 🎯 Checklist przed Demo

### ✅ Backend
- [ ] `node server.js` działa bez błędów
- [ ] `curl http://localhost:8000/api/health` zwraca `{"status":"ok"}`
- [ ] Dataset zaimportowany (min. 3 osoby)
- [ ] `verify_db.js` pokazuje osoby w bazie

### ✅ Web
- [ ] Plik `config.json` ma poprawny URL
- [ ] Strona ładuje się bez błędów (F12 Console czysta)
- [ ] Test upload zdjęcia działa

### ✅ Desktop
- [ ] `python3 main.py` uruchamia okno
- [ ] Test rozpoznania działa
- [ ] Wynik pokazuje nazwę + confidence

### ✅ Mobile
- [ ] APK zainstalowany na telefonie
- [ ] `appsettings.json` ma poprawny IP
- [ ] Ping do serwera działa
- [ ] Aplikacja łączy się z API

### ✅ Network (dla multi-device)
- [ ] Wszystkie urządzenia w tej samej sieci
- [ ] Firewall przepuszcza port 8000
- [ ] Ping między urządzeniami działa

---

## 📞 Wsparcie

**Logowanie:**
- Backend: konsola serwera (`node server.js`)
- Web: Browser Console (F12)
- Desktop: Terminal output
- Mobile: Visual Studio Output / Logcat (Android)

**Testy:**
```bash
# Backend API
cd backend/testy sh
./run_all_tests.sh

# Pojedyncze testy
./test_a5.sh  # /recognize endpoint
./test_a6.sh  # /persons endpoint
./test_a7.sh  # health check
```

**Przydatne komendy:**
```bash
# Sprawdź bazy danych
node verify_db.js

# Import pojedynczej osoby
curl -X POST http://localhost:8000/api/persons \
  -F "name=Test Person" \
  -F "image=@test_face.jpg"

# Test rozpoznania
curl -X POST http://localhost:8000/api/recognize \
  -F "image=@test_face.jpg"
```

---

## 🎉 Gotowe!

Twój system rozpoznawania twarzy jest gotowy. Powodzenia na demo! 🚀

**Quick Start (wszystko naraz):**
```bash
# Terminal 1 - Backend
cd backend && node server.js

# Terminal 2 - Web
cd frontend-web && python3 -m http.server 8080

# Terminal 3 - Desktop
cd frontend-web && python3 main.py

# Mobile - build i install na telefon osobno
```
