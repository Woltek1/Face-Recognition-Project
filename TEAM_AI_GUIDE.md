# 🤖 Przewodnik pracy z AI dla projektu: System Rozpoznawania Twarzy
> Wklej ten plik jako **pierwszy prompt** do Claude.ai przed rozpoczęciem pracy nad swoją częścią projektu.
> Następnie pracuj normalnie — Claude będzie trzymał się tych wytycznych przez całą sesję.

---

## 📌 KONTEKST PROJEKTU (wspólny dla wszystkich)

Tworzymy system rozpoznawania twarzy składający się z czterech osobnych części:
- **Backend API** — serwer Node.js/Express.js obsługujący model DeepFace (przez skrypt Python)
- **Frontend Web** — strona HTML/JS wysyłająca zdjęcia do API
- **Aplikacja Desktopowa** — PyQt6 lub WPF z wyborem pliku lokalnego
- **Aplikacja Mobilna** — .NET MAUI z dostępem do aparatu

Wszystkie części komunikują się przez jedno REST API. Pracujemy oddzielnie, ale musimy być spójni, żeby integracja na końcu była możliwa.

---

## 🔗 KONTRAKT API — NIENARUSZALNY DLA WSZYSTKICH

> ⚠️ Żaden z członków zespołu nie może zmieniać poniższych formatów bez poinformowania reszty.
> Claude ma zawsze generować kod zgodny z tym kontraktem, nawet jeśli zaproponowałby inne rozwiązanie.

### Base URL
```
http://<SERVER_IP>:8000/api
```
*(Docelowy adres IP zostanie ustalony przy integracji. W trakcie pracy używaj `http://localhost:8000/api`)*

---

### `POST /api/recognize` — Rozpoznawanie twarzy

**Żądanie:**
```
Content-Type: multipart/form-data
Pole: "image" (plik jpg lub png)
```

**Odpowiedź — twarz rozpoznana (HTTP 200):**
```json
{
  "matched": true,
  "person": "Jan Kowalski",
  "confidence": 0.91
}
```

**Odpowiedź — twarz nierozpoznana (HTTP 200):**
```json
{
  "matched": false,
  "person": null,
  "confidence": 0.0
}
```

**Odpowiedź — błąd (HTTP 400 lub 500):**
```json
{
  "error": "No face detected in image"
}
```

---

### `POST /api/persons` — Dodanie nowej osoby do bazy

**Żądanie:**
```
Content-Type: multipart/form-data
Pola: "name" (string), "image" (plik jpg lub png)
```

**Odpowiedź sukces (HTTP 201):**
```json
{
  "id": 1,
  "name": "Jan Kowalski",
  "message": "Person added successfully"
}
```

**Odpowiedź błąd (HTTP 400):**
```json
{
  "error": "No face detected in image"
}
```

---

### `GET /api/health` — Sprawdzenie czy serwer działa

**Odpowiedź (HTTP 200):**
```json
{
  "status": "ok"
}
```

---

## 🗂️ STRUKTURA REPOZYTORIUM GIT

Repozytorium ma następującą strukturę folderów. Każdy pracuje **tylko w swoim folderze**.

```
projekt-twarze/
├── backend/          ← Osoba A
├── frontend-web/     ← Osoba B
├── desktop/          ← Osoba B
├── mobile/           ← Osoba C
├── docs/
│   └── API_CONTRACT.md
├── mock_server.py    ← wspólny mock do testów
└── README.md
```

> Claude ma generować pliki tylko w folderze odpowiadającym danej osobie, chyba że wyraźnie zaznaczono inaczej.

---

## 🌐 MOCK SERWER (dla Osób B i C podczas developmentu)

Dopóki backend nie jest gotowy, uruchamiaj ten plik lokalnie:

```python
# mock_server.py — uruchom: pip install flask && python mock_server.py
from flask import Flask, jsonify, request
app = Flask(__name__)

@app.route('/api/recognize', methods=['POST'])
def recognize():
    # Symuluje rozpoznaną twarz
    return jsonify({"matched": True, "person": "Jan Kowalski", "confidence": 0.91}), 200

@app.route('/api/persons', methods=['POST'])
def add_person():
    return jsonify({"id": 1, "name": "Test", "message": "Person added successfully"}), 201

@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
```

---

---

# 👤 OSOBA A — Backend + Model ML

> Wklej całą sekcję „KONTEKST PROJEKTU" + „KONTRAKT API" + tę sekcję jako pierwszy prompt.

## Twoja rola
Tworzysz serwer oparty na **Express.js** (Node.js), który odbiera zdjęcia od klientów i przekazuje je do **skryptu Python z DeepFace** w celu rozpoznania twarzy. Wyniki trafiają do bazy danych SQLite. Backend składa się z dwóch współpracujących części: serwera JS i skryptu Python — ale dla klientów wygląda jak jeden serwer.

## Architektura backendu

```
Klient (web/desktop/mobile)
        │  HTTP POST /api/recognize
        ▼
[ Express.js — server.js ]   ← obsługa HTTP, routing, baza danych
        │  child_process.spawn()
        ▼
[ face_service.py ]          ← DeepFace, generowanie embeddingów, porównywanie
        │  JSON przez stdout
        ▼
[ Express.js ]               ← zwraca wynik do klienta
```

## Technologia (nienaruszalne)
- **Serwer:** Node.js 20+ + Express.js 4.x
- **Baza danych:** SQLite przez bibliotekę `better-sqlite3`
- **Model ML:** Python 3.10+ + DeepFace — model **Facenet512**
- **Komunikacja Node↔Python:** `child_process.spawn()` — Node wywołuje skrypt Python, odbiera JSON przez stdout
- **Port serwera:** `8000`

## Zasady, których Claude ma przestrzegać

### Zasady Express.js

1. **Wszystkie endpointy muszą być zgodne z kontraktem API** zdefiniowanym powyżej — żadnych własnych formatów odpowiedzi JSON.

2. **CORS musi być włączony** dla wszystkich origins (`*`) — użyj pakietu `cors`:
   ```javascript
   const cors = require('cors');
   app.use(cors());
   ```

3. **Upload plików przez `multer`** — pliki tymczasowe zapisuj do folderu `uploads/tmp/`, usuń plik po zakończeniu przetwarzania.

4. **Każdy endpoint musi obsługiwać błędy** i zwracać `{"error": "opis"}` ze stosownym kodem HTTP (400 dla błędów użytkownika, 500 dla błędów serwera).

5. **Serwer nasłuchuje na `0.0.0.0:8000`** — nie tylko `localhost`:
   ```javascript
   app.listen(8000, '0.0.0.0', () => console.log('Server running on port 8000'));
   ```

6. **Próg podobieństwa jako stała** w pliku `config.js`:
   ```javascript
   module.exports = { MATCH_THRESHOLD: 0.4 }; // cosine distance dla Facenet512
   ```

7. **Loguj do konsoli** każde żądanie rozpoznawania: timestamp, wynik dopasowania i czas przetwarzania w ms.

8. **Embeddingi w bazie danych przechowuj jako TEXT** (JSON.stringify tablicy float) — nie jako BLOB.

### Zasady skryptu Python (face_service.py)

9. **Skrypt Python komunikuje się wyłącznie przez stdin/stdout** — przyjmuje ścieżkę do pliku jako argument, zwraca JSON na stdout, błędy na stderr:
   ```python
   # Wywołanie: python face_service.py --image /tmp/photo.jpg --mode recognize
   # Wyjście na stdout: {"matched": true, "person": "Jan Kowalski", "confidence": 0.91}
   ```

10. **DeepFace importuj na poziomie modułu** (raz przy starcie skryptu), nie wewnątrz funkcji — skrypt jest wywoływany per żądanie, więc nie ma "ciepłego cache'u", ale import musi być czysty.

11. **Skrypt importu datasetu** uruchamiany osobno:
    ```
    node import_dataset.js --path ./dataset
    ```
    Dataset zakłada strukturę: `dataset/NazwaOsoby/zdjecie.jpg`. Skrypt JS wywołuje `face_service.py` dla każdego zdjęcia i zapisuje embeddingi do bazy.

12. **Nie używaj absolutnych ścieżek** — tylko ścieżki względne lub zmienne z pliku `.env`.

### Komunikacja Node.js ↔ Python

Claude ma generować komunikację w tym wzorcu:
```javascript
// W Express.js — wywołanie skryptu Python
const { spawn } = require('child_process');

function callFaceService(imagePath, mode) {
  return new Promise((resolve, reject) => {
    const py = spawn('python', ['face_service.py', '--image', imagePath, '--mode', mode]);
    let output = '';
    let errorOutput = '';

    py.stdout.on('data', (data) => { output += data.toString(); });
    py.stderr.on('data', (data) => { errorOutput += data.toString(); });

    py.on('close', (code) => {
      if (code !== 0) return reject(new Error(errorOutput));
      try { resolve(JSON.parse(output)); }
      catch (e) { reject(new Error('Invalid JSON from Python script')); }
    });
  });
}
```

## Struktura projektu do wygenerowania
```
backend/
├── server.js               ← główny serwer Express
├── routes/
│   └── api.js              ← endpointy /recognize, /persons, /health
├── db/
│   ├── database.js         ← połączenie z SQLite, inicjalizacja tabel
│   └── faces.db            ← plik bazy (tworzony automatycznie)
├── face_service.py         ← cała logika DeepFace (Python)
├── import_dataset.js       ← skrypt importu datasetu (Node.js)
├── config.js               ← stałe (MATCH_THRESHOLD, PORT, etc.)
├── uploads/
│   └── tmp/                ← tymczasowe pliki (dodaj do .gitignore)
├── package.json            ← OBOWIĄZKOWY z wersjami
├── requirements.txt        ← zależności Python z wersjami
├── .env.example            ← wzorzec zmiennych środowiskowych
└── README_BACKEND.md       ← instrukcja uruchomienia
```

## Obowiązkowy `package.json` — zależności Node.js
Claude ma zawsze generować z konkretnymi wersjami:
```json
{
  "dependencies": {
    "express": "4.18.2",
    "cors": "2.8.5",
    "multer": "1.4.5-lts.1",
    "better-sqlite3": "9.4.3",
    "dotenv": "16.3.1"
  }
}
```

## Obowiązkowy `requirements.txt` — zależności Python
```
deepface==0.0.86
tensorflow==2.13.0
pillow==10.1.0
numpy==1.24.3
```

## Obowiązkowy `.env.example`
```
PORT=8000
DB_PATH=./db/faces.db
UPLOADS_TMP=./uploads/tmp
MATCH_THRESHOLD=0.4
PYTHON_PATH=python
```

## README_BACKEND.md — minimalna zawartość
Claude ma wygenerować plik z instrukcją zawierającą:
- Wymagania wstępne (Node.js 20+, Python 3.10+)
- Instalacja zależności Node: `npm install`
- Instalacja zależności Python: `pip install -r requirements.txt`
- Konfiguracja: `cp .env.example .env`
- Import datasetu: `node import_dataset.js --path ./dataset`
- Uruchomienie serwera: `node server.js`
- Weryfikacja działania: `curl http://localhost:8000/api/health`

---

---

# 👤 OSOBA B — Frontend Web + Aplikacja Desktopowa

> Wklej całą sekcję „KONTEKST PROJEKTU" + „KONTRAKT API" + tę sekcję jako pierwszy prompt.

## Twoja rola
Tworzysz dwa niezależne klienty: stronę webową (HTML/CSS/JS) i aplikację desktopową (PyQt6 lub WPF), które wysyłają zdjęcia do backendu i wyświetlają wynik.

## Technologia

### Frontend Web
- **Język:** HTML5 + CSS3 + Vanilla JavaScript (bez frameworków, chyba że znasz React/Vue)
- **Żadnych zewnętrznych backendów** — tylko statyczne pliki serwowane z folderu `frontend-web/`
- **Przeglądarka docelowa:** Chrome / Edge (nowoczesny)

### Aplikacja Desktopowa
- **Opcja 1 (rekomendowana):** Python 3.10+ + **PyQt6**
- **Opcja 2:** C# + **WPF** (.NET 8)
- Wybierz jedną opcję i trzymaj się jej przez cały projekt.

## Zasady dla Frontendu Web, których Claude ma przestrzegać

1. **Adres API jako stała** na górze pliku JS:
   ```javascript
   const API_URL = 'http://localhost:8000/api'; // zmień na właściwy adres przy integracji
   ```
   Nigdzie indziej w kodzie nie może być hardcoded URL.

2. **Wysyłanie zdjęcia przez FormData:**
   ```javascript
   const formData = new FormData();
   formData.append('image', fileInput.files[0]);
   const response = await fetch(`${API_URL}/recognize`, { method: 'POST', body: formData });
   ```
   Nie konwertuj do base64 — backend oczekuje multipart/form-data.

3. **Obsługa wszystkich stanów UI:**
   - Stan domyślny (brak zdjęcia)
   - Podgląd wybranego zdjęcia przed wysłaniem
   - Ładowanie (spinner lub komunikat "Sprawdzanie...")
   - Wynik pozytywny (zielone podświetlenie + imię osoby + confidence)
   - Wynik negatywny (czerwone podświetlenie + "Nie rozpoznano")
   - Błąd sieci / błąd serwera (komunikat dla użytkownika)

4. **Brak alertów JavaScript** (`alert()`, `confirm()`) — wszystkie komunikaty w HTML.

5. **Jeden plik HTML** z osadzonym CSS i JS (lub max 3 pliki: index.html, style.css, app.js).

6. **Responsywność** — strona ma działać na ekranach od 768px szerokości.

## Zasady dla Aplikacji Desktopowej, których Claude ma przestrzegać

1. **Adres API w pliku konfiguracyjnym** `config.json` w folderze aplikacji:
   ```json
   {
     "api_url": "http://localhost:8000/api"
   }
   ```
   Aplikacja ma wczytywać ten plik przy starcie. Użytkownik może go edytować bez dotykania kodu.

2. **Okno główne** musi zawierać:
   - Przycisk "Wybierz plik" otwierający systemowy dialog pliku (filtr: `*.jpg *.jpeg *.png`)
   - Obszar podglądu wybranego zdjęcia
   - Przycisk "Sprawdź twarz" (nieaktywny dopóki nie wybrano pliku)
   - Pole tekstowe / etykieta z wynikiem
   - Wskaźnik ładowania podczas oczekiwania na odpowiedź

3. **Wysyłanie przez HTTP multipart** — dla PyQt6 użyj biblioteki `requests`, dla WPF użyj `HttpClient`.

4. **Operacje sieciowe w osobnym wątku** — UI nie może się zawieszać podczas czekania na API. Dla PyQt6: `QThread`, dla WPF: `async/await`.

5. **Obsługa błędów:** timeout po 30 sekundach, komunikat gdy serwer niedostępny, komunikat gdy brak twarzy na zdjęciu.

6. **Nie pakuj modelu ML do aplikacji desktopowej** — wysyła tylko zdjęcie do API, nie przetwarza lokalnie.

## Struktura projektu do wygenerowania

```
frontend-web/
├── index.html
├── style.css          (opcjonalnie)
├── app.js             (opcjonalnie)
└── README_WEB.md

desktop/
├── main.py            (lub MainWindow.xaml dla WPF)
├── config.json
├── requirements.txt   (dla PyQt6)
└── README_DESKTOP.md
```

## Obowiązkowy plik `requirements.txt` (jeśli PyQt6)
```
PyQt6==6.6.0
requests==2.31.0
```

## README — minimalna zawartość dla każdej aplikacji
- Jak uruchomić (`python main.py` lub jak zbudować WPF)
- Jak zmienić adres serwera (edycja `config.json`)
- Wymagania systemowe

---

---

# 👤 OSOBA C — Aplikacja Mobilna + Testy + Dokumentacja

> Wklej całą sekcję „KONTEKST PROJEKTU" + „KONTRAKT API" + tę sekcję jako pierwszy prompt.

## Twoja rola
Tworzysz aplikację mobilną (.NET MAUI) dla Android/iOS, która pozwala zrobić zdjęcie aparatem i wysłać je do API. Dodatkowo testujesz cały system i tworzysz dokumentację.

## Technologia (nie negocjowalny)
- **Platforma:** .NET MAUI (.NET 8)
- **Język:** C#
- **Docelowy system:** Android (minimum API level 26 = Android 8.0)
- **IDE:** Visual Studio 2022 z workload MAUI

## Zasady dla Aplikacji Mobilnej, których Claude ma przestrzegać

1. **Adres API w pliku `appsettings.json`** lub jako stała w klasie `AppConfig.cs`:
   ```csharp
   public static class AppConfig
   {
       public static string ApiUrl { get; set; } = "http://10.0.2.2:8000/api";
       // 10.0.2.2 to adres hosta z emulatora Android — zamień na IP przy testach na prawdziwym urządzeniu
   }
   ```

2. **Ekran główny** musi zawierać:
   - Przycisk "Zrób zdjęcie" (aparat)
   - Przycisk "Wybierz z galerii"
   - Obszar podglądu wybranego/zrobionego zdjęcia (`Image` control)
   - Przycisk "Sprawdź twarz" (nieaktywny dopóki brak zdjęcia)
   - Etykieta z wynikiem rozpoznawania
   - ActivityIndicator podczas ładowania

3. **Uprawnienia do aparatu i galerii** muszą być poprawnie zadeklarowane:
   - W `AndroidManifest.xml`: `CAMERA`, `READ_EXTERNAL_STORAGE`
   - Użyj `MediaPicker.Default.CapturePhotoAsync()` dla aparatu
   - Użyj `MediaPicker.Default.PickPhotoAsync()` dla galerii

4. **Wysyłanie zdjęcia przez HTTP multipart:**
   ```csharp
   using var content = new MultipartFormDataContent();
   var imageContent = new ByteArrayContent(imageBytes);
   imageContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
   content.Add(imageContent, "image", "photo.jpg");
   var response = await httpClient.PostAsync($"{AppConfig.ApiUrl}/recognize", content);
   ```
   Nie używaj base64. Backend oczekuje multipart/form-data z polem `"image"`.

5. **HttpClient jako singleton** — jedna instancja na całą aplikację (zarejestrowana w `MauiProgram.cs`):
   ```csharp
   builder.Services.AddSingleton<HttpClient>();
   ```

6. **Wszystkie wywołania API w `async/await`** — nie blokuj wątku UI.

7. **Timeout HttpClient: 30 sekund.**

8. **Obsługa błędów:**
   - Brak internetu / serwer niedostępny → komunikat "Nie można połączyć z serwerem"
   - HTTP 400 → wyświetl pole `error` z odpowiedzi JSON
   - HTTP 500 → "Błąd serwera, spróbuj ponownie"

9. **Zdjęcie przed wysłaniem przeskaluj** do max 800x800 px (zachowując proporcje) — DeepFace nie potrzebuje wyższej rozdzielczości, a zmniejszy to czas przesyłania.

10. **Ekran ustawień** (opcjonalnie, ale zalecany): proste pole tekstowe do zmiany `ApiUrl` bez edycji kodu.

## Zasady dla Dokumentacji i Testów

### Plik `docs/TESTY.md` — format tabeli wyników

Claude ma generować plik testów w tej strukturze:

```markdown
# Wyniki testów end-to-end

## Środowisko testowe
- Wersja backendu: x.x
- Data testów: DD.MM.RRRR
- Urządzenie mobilne: [model telefonu / emulator]
- System operacyjny desktop: [Windows/Linux/Mac]

## Tabela wyników

| # | Aplikacja | Zdjęcie wejściowe | Osoba w bazie? | Oczekiwany wynik | Otrzymany wynik | Confidence | Status |
|---|-----------|-------------------|----------------|------------------|-----------------|------------|--------|
| 1 | Web       | jan_kowalski.jpg  | TAK            | matched: true    | matched: true   | 0.89       | ✅ PASS |
| 2 | Desktop   | nieznajomy.jpg    | NIE            | matched: false   | matched: false  | 0.0        | ✅ PASS |
| 3 | Mobile    | rozmyte.jpg       | TAK            | error            | matched: true   | 0.51       | ❌ FAIL |

## Napotkane błędy i ich rozwiązania
[opis]
```

### Plik `README.md` — główny plik projektu

Claude ma wygenerować README z następującymi sekcjami:
1. Opis projektu (2-3 zdania)
2. Architektura systemu (prosty diagram tekstowy)
3. Wymagania wstępne (Python, .NET, Node, etc. z wersjami)
4. Instrukcja uruchomienia backendu (krok po kroku)
5. Instrukcja uruchomienia frontendu web
6. Instrukcja uruchomienia aplikacji desktopowej
7. Instrukcja uruchomienia aplikacji mobilnej
8. Jak zmienić adres serwera w każdej aplikacji
9. Znane problemy / ograniczenia

---

---

# ✅ ZASADY WSPÓLNE DLA WSZYSTKICH OSÓB

> Claude ma stosować te zasady niezależnie od tego, która osoba używa tego pliku.

## Kodowanie i nazewnictwo

- **Komentarze w kodzie po angielsku** (standard w programowaniu)
- **Nazwy zmiennych i funkcji po angielsku** (`getEmbedding`, nie `pobierzEmbedding`)
- **Komunikaty dla użytkownika po polsku** (w UI aplikacji)
- **Nazwy plików bez polskich znaków** i bez spacji (używaj myślników: `main-window.py`)

## Bezpieczeństwo i konfiguracja

- **Żadnych haseł ani kluczy API w kodzie** — używaj zmiennych środowiskowych lub plików `.env`
- **Plik `.env` i `config.json` z prawdziwymi danymi** zawsze w `.gitignore`
- **Dostarcz plik `.env.example`** z pustymi wartościami jako wzorzec

## Git i praca z kodem

- **Commituj często** — po każdym działającym kroku, nie tylko na końcu
- **Nazwy commitów opisowe:** `Add face recognition endpoint` nie `update` ani `fix`
- **Pracuj tylko w swoim folderze** — nie modyfikuj plików innych osób
- **Przed integracją** przetestuj lokalnie z mock serverem

## Obsługa błędów

- **Każda operacja sieciowa** musi mieć obsługę wyjątków / błędów
- **Nigdy nie pokazuj stack trace użytkownikowi** — tylko przyjazny komunikat
- **Loguj błędy do konsoli** (nie do UI) dla celów debugowania

## Testowanie przed oddaniem

Każda osoba przed zgłoszeniem gotowości do integracji musi sprawdzić:
- [ ] Aplikacja startuje bez błędów
- [ ] Wysłanie poprawnego zdjęcia zwraca wynik
- [ ] Wysłanie zdjęcia bez twarzy nie crashuje aplikacji
- [ ] Brak połączenia z serwerem nie crashuje aplikacji
- [ ] Adres serwera można zmienić bez edycji kodu źródłowego

---

## 🚨 Czego Claude NIE POWINIEN robić w tym projekcie

- ❌ Zmieniać formatu JSON odpowiedzi API bez wyraźnej prośby
- ❌ Dodawać autentykacji/logowania (poza zakresem projektu)
- ❌ Implementować rozpoznawania twarzy lokalnie w aplikacjach klienckich (tylko backend to robi)
- ❌ Używać przestarzałych bibliotek (np. PyQt5 zamiast PyQt6, .NET 6 zamiast .NET 8)
- ❌ Hardcodować adresu IP serwera w kodzie źródłowym
- ❌ Generować kodu bez obsługi błędów sieciowych
- ❌ Tworzyć plików poza folderem swojej części projektu
- ❌ W backendzie: zastępować `child_process.spawn()` innym mechanizmem bez konsultacji (np. osobny serwer Flask) — chyba że wyraźnie o to poprosisz
- ❌ W backendzie: wywoływać DeepFace bezpośrednio z Node.js przez żadne inne mosty niż uzgodniony skrypt Python

---

*Ostatnia aktualizacja kontraktu: ustalona wspólnie przed rozpoczęciem projektu. Jakakolwiek zmiana wymaga zgody wszystkich 3 osób.*
