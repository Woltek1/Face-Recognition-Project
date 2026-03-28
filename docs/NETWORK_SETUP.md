# 🌐 Network Setup Guide - Multi-Device Demo

## Cel: Wszystkie urządzenia łączą się z jednym backendem

```
┌──────────────┐
│   Router     │ 192.168.1.1
└──────┬───────┘
       │
   ┌───┴────┬────────┬─────────┐
   │        │        │         │
┌──▼──┐  ┌─▼──┐  ┌──▼───┐  ┌──▼────┐
│ PC  │  │Web │  │Mobile│  │Tablet │
│8000 │  │ :80│  │ App  │  │  App  │
└─────┘  └────┘  └──────┘  └───────┘
Backend  Client  Client    Client
.100     .101    .102      .103
```

---

## Krok 1: Znajdź IP Komputera z Backendem

### Windows
```cmd
ipconfig

# Szukaj "IPv4 Address" w sekcji Wi-Fi lub Ethernet
# Przykład: 192.168.1.100
```

### macOS
```bash
ifconfig en0 | grep "inet "

# Lub prostsze:
ipconfig getifaddr en0

# Wynik: 192.168.1.100
```

### Linux
```bash
hostname -I

# Lub:
ip addr show | grep "inet "

# Wynik: 192.168.1.100
```

**Zapisz to IP!** Będziemy go używać w konfiguracji.

---

## Krok 2: Upewnij się że Backend nasłuchuje na 0.0.0.0

### Sprawdź server.js (powinno być domyślnie OK)

```javascript
app.listen(config.PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${config.PORT}`);
});
```

**0.0.0.0 = wszystkie interfejsy sieciowe** (nie tylko localhost!)

### Restart backend
```bash
cd backend
node server.js

# Powinieneś zobaczyć:
# Server running on http://0.0.0.0:8000
```

---

## Krok 3: Konfiguracja Firewall

### Windows

**Opcja A - GUI:**
1. Wyszukaj "Windows Defender Firewall"
2. Kliknij "Advanced settings"
3. "Inbound Rules" → "New Rule..."
4. Port → TCP → 8000
5. Allow the connection
6. Nazwij regułę: "Face Recognition Backend"

**Opcja B - PowerShell (jako Admin):**
```powershell
New-NetFirewallRule -DisplayName "Face Recognition Backend" `
  -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow
```

**Test:**
```powershell
netstat -an | findstr :8000
# Powinno pokazać: 0.0.0.0:8000
```

### macOS

**Sprawdź firewall:**
```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Jeśli enabled:
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add node
sudo pkill -HUP socketfilterfw
```

**Lub wyłącz firewall tymczasowo (tylko do demo!):**
```bash
System Preferences → Security & Privacy → Firewall → Turn Off Firewall
```

### Linux (ufw)

```bash
# Dodaj regułę
sudo ufw allow 8000/tcp

# Sprawdź status
sudo ufw status

# Powinno pokazać:
# 8000/tcp    ALLOW    Anywhere
```

---

## Krok 4: Test Połączenia z Innego Urządzenia

### Z innego komputera/laptopa w tej samej sieci:

```bash
# Zastąp 192.168.1.100 swoim IP
curl http://192.168.1.100:8000/api/health

# Powinieneś dostać:
# {"status":"ok"}
```

### Z telefonu:

**Opcja A - Przeglądarka:**
- Otwórz: `http://192.168.1.100:8000/api/health`
- Powinno pokazać: `{"status":"ok"}`

**Opcja B - App "Network Utilities" (Android):**
1. Zainstaluj z Play Store
2. Ping → `192.168.1.100`
3. Port Scanner → `192.168.1.100:8000`

**Jeśli NIE działa:**
- Sprawdź czy firewall jest skonfigurowany
- Sprawdź czy urządzenia są w tej samej sieci (to samo Wi-Fi!)
- Sprawdź czy backend działa (`curl http://localhost:8000/api/health` z serwera)

---

## Krok 5: Konfiguracja Klientów

### Web Frontend

Edytuj `frontend-web/config.json`:
```json
{
  "api_url": "http://192.168.1.100:8000/api"
}
```

### Desktop (PyQt6)

To samo - edytuj `frontend-web/config.json`:
```json
{
  "api_url": "http://192.168.1.100:8000/api"
}
```

### Mobile (MAUI)

Edytuj `mobile/appsettings.json`:

**Android Emulator:**
```json
{
  "ApiBaseUrl": "http://10.0.2.2:8000/api"
}
```
*10.0.2.2 to alias dla localhost hosta*

**iOS Simulator:**
```json
{
  "ApiBaseUrl": "http://192.168.1.100:8000/api"
}
```
*Użyj prawdziwego IP*

**Fizyczne Urządzenie (Android/iOS):**
```json
{
  "ApiBaseUrl": "http://192.168.1.100:8000/api"
}
```
*Użyj IP z kroku 1*

---

## Krok 6: Rebuild i Test

### Web
```bash
# Restart serwera
cd frontend-web
python3 -m http.server 8080

# Otwórz z innego urządzenia:
http://192.168.1.101:8080  # IP laptopa z web frontend
```

### Desktop
```bash
# Po zmianie config.json:
python3 main.py

# Wybierz zdjęcie → test
```

### Mobile
```bash
# Android
dotnet clean
dotnet build -f net10.0-android
dotnet run -f net10.0-android

# iOS
dotnet clean
dotnet build -f net10.0-ios
dotnet run -f net10.0-ios
```

---

## 📱 Testowanie z Fizycznego Urządzenia

### Przygotowanie

1. **Sprawdź IP telefonu:**
   - Android: Settings → About phone → Status → IP address
   - iOS: Settings → Wi-Fi → (i) → IP Address

2. **Ta sama sieć:**
   - Komputer i telefon MUSZĄ być w tym samym Wi-Fi
   - Nie używaj "Guest Network" (często zablokowany device-to-device)

3. **USB Debugging (Android):**
   - Settings → About phone → Tap "Build number" 7 razy
   - Settings → Developer options → Enable "USB debugging"

### Deploy na Android

```bash
# Podłącz USB
adb devices  # Powinno pokazać urządzenie

# Build Release
dotnet publish -f net10.0-android -c Release

# Install
adb install bin/Release/net10.0-android/publish/*.apk
```

### Deploy na iOS (macOS + Xcode)

```bash
# Build
dotnet build -f net10.0-ios -c Release

# W Xcode:
# 1. Otwórz projekt
# 2. Wybierz swój iPhone
# 3. Build & Run
```

---

## 🎬 Demo Scenario: Multi-Device

### Setup (10 min przed demo)

**Urządzenie 1 - Backend Server (Komputer główny):**
```bash
IP: 192.168.1.100
cd backend
node server.js
```

**Urządzenie 2 - Web Frontend (Laptop):**
```bash
IP: 192.168.1.101
cd frontend-web
# Config: api_url = http://192.168.1.100:8000/api
python3 -m http.server 8080
```

**Urządzenie 3 - Mobile (Telefon Android):**
```bash
IP: 192.168.1.102
# appsettings.json: ApiBaseUrl = http://192.168.1.100:8000/api
# Zainstaluj APK
```

**Urządzenie 4 - Desktop (Tablet/Laptop #2):**
```bash
IP: 192.168.1.103
cd frontend-web
# Config: api_url = http://192.168.1.100:8000/api
python3 main.py
```

### Test Connectivity Matrix

| From → To | Backend .100 | Web .101 | Mobile .102 | Desktop .103 |
|-----------|--------------|----------|-------------|--------------|
| Backend .100 | localhost | ✓ | ✓ | ✓ |
| Web .101 | ✓ | localhost | - | - |
| Mobile .102 | ✓ | - | localhost | - |
| Desktop .103 | ✓ | - | - | localhost |

*Tylko klienci łączą się z backendem, nie ze sobą nawzajem*

### Demo Flow

1. **Pokaż backend:**
   - Terminal z `node server.js`
   - Logi requestów

2. **Web:** Prześlij zdjęcie
   - Pokaż animacje
   - Zobacz log na backendzie

3. **Mobile:** Zrób zdjęcie
   - To samo zdjęcie co web
   - Pokaż że wynik jest identyczny

4. **Desktop:** Wybierz zdjęcie
   - Inne zdjęcie
   - Pokaż inne rozpoznanie

5. **Jednocześnie:** Wszystkie 3 klienty naraz
   - Pokaż że backend obsługuje concurrent requests

---

## 🔧 Troubleshooting Network

### Problem: "Connection refused" z telefonu

**Diagnoza:**
```bash
# Na komputerze:
curl http://localhost:8000/api/health  # OK?
curl http://192.168.1.100:8000/api/health  # OK?

# Z telefonu (przeglądarka):
http://192.168.1.100:8000/api/health  # NIE DZIAŁA?
```

**Rozwiązanie:**
1. Firewall - sprawdź czy port 8000 jest otwarty
2. Network - sprawdź czy ta sama sieć
3. Backend - sprawdź czy nasłuchuje na 0.0.0.0 (nie tylko 127.0.0.1)

### Problem: "Timeout" z mobile app

**Diagnoza:**
```bash
# Ping test
ping 192.168.1.100  # Z telefonu

# Port test (Network Utilities app)
192.168.1.100:8000  # Powinno być "Open"
```

**Rozwiązanie:**
- Zwiększ timeout w `FaceRecognitionService.cs`:
```csharp
_httpClient = new HttpClient
{
    Timeout = TimeSpan.FromSeconds(60)  // Było 30
};
```

### Problem: Router blokuje inter-device communication

**Symptom:**
- Ping działa
- Port 8000 jest otwarty
- Ale HTTP request nie przechodzi

**Rozwiązanie:**
1. Sprawdź router settings → "AP Isolation" lub "Client Isolation"
2. Wyłącz AP Isolation
3. Restart router
4. Lub użyj przewodowego połączenia (Ethernet)

### Problem: "No route to host"

**Rozwiązanie:**
```bash
# Sprawdź IP jeszcze raz
ipconfig  # Windows
ifconfig  # Mac/Linux

# Sprawdź czy IP się nie zmienił (DHCP)
# Jeśli się zmienił - ustaw Static IP:

# Windows: Network Settings → Change adapter options → Properties → IPv4
# Mac: System Preferences → Network → Advanced → TCP/IP → Configure IPv4: Manually
# Linux: /etc/network/interfaces (lub NetworkManager)
```

---

## 💡 Pro Tips

### Static IP dla Backend Server

**Dlaczego?**
- IP nie zmieni się po restarcie
- Nie trzeba zmieniać config.json za każdym razem

**Jak?**
1. Router → DHCP Settings → Static IP Mapping
2. Przypisz MAC Address serwera → Stały IP (np. 192.168.1.100)

### mDNS/Bonjour (zaawansowane)

**Zamiast IP użyj hostname:**
```json
{
  "api_url": "http://server-name.local:8000/api"
}
```

**Wymaga:**
- macOS: Działa out-of-the-box
- Windows: Zainstaluj Bonjour Service
- Linux: Zainstaluj avahi-daemon

### Mobile Hotspot (backup plan)

**Jeśli Wi-Fi nie działa:**
1. Włącz hotspot na telefonie
2. Podłącz laptop do hotspotu
3. Backend na laptopie
4. Mobile app na telefonie
5. IP laptopa będzie 192.168.43.1 (Android) lub 172.20.10.1 (iOS)

---

## ✅ Pre-Demo Checklist

### 1 godzina przed demo:
- [ ] Wszystkie urządzenia naładowane (100%)
- [ ] Wszystkie urządzenia w tej samej sieci
- [ ] Backend działa: `curl http://IP:8000/api/health`
- [ ] Firewall skonfigurowany
- [ ] Config files zaktualizowane z prawdziwym IP

### 30 minut przed demo:
- [ ] Ping test z każdego urządzenia
- [ ] Port scan (8000) z każdego urządzenia
- [ ] Test end-to-end z każdego klienta
- [ ] Dataset zaimportowany
- [ ] Przykładowe zdjęcia przygotowane

### 5 minut przed demo:
- [ ] Restart wszystkich aplikacji
- [ ] Clear cache w przeglądarkach
- [ ] Final test: 1 zdjęcie z każdego klienta

---

## 🎓 Dla Zaawansowanych

### Load Balancing (multiple backends)

```
┌──────┐  ┌──────┐  ┌──────┐
│Back 1│  │Back 2│  │Back 3│
└───┬──┘  └───┬──┘  └───┬──┘
    │         │         │
    └─────┬───┴─────────┘
          │
     ┌────▼────┐
     │  Nginx  │ :8000
     │Load Bal │
     └─────────┘
```

### HTTPS (production)

```bash
# Generate cert
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365

# Update server.js
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem')
};

https.createServer(options, app).listen(8443);
```

**Config:**
```json
{
  "api_url": "https://192.168.1.100:8443/api"
}
```

---

**Network setup complete!** 🎉 Wszystkie urządzenia powinny teraz komunikować się z backendem.
