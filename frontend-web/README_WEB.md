# Frontend Web — System Rozpoznawania Twarzy

## Uruchomienie

Otwórz `index.html` bezpośrednio w przeglądarce **lub** serwuj przez dowolny statyczny serwer:

```bash
# Przykład z Pythonem
python -m http.server 5500

# Lub z Node.js (npx)
npx serve .
```

Następnie wejdź na `http://localhost:5500`.

## Zmiana adresu serwera

Na górze pliku `index.html`, w sekcji `<script>`, zmień wartość stałej:

```javascript
const API_URL = 'http://localhost:8000/api'; // ← zmień tutaj
```

Wpisz adres docelowego serwera zamiast `localhost`.

## Wymagania systemowe

- Nowoczesna przeglądarka: Chrome 90+ / Edge 90+
- Szerokość ekranu: minimum 768px
- Backend musi być uruchomiony i dostępny

## Funkcje

- Wybór pliku przez kliknięcie lub przeciągnięcie (drag & drop)
- Podgląd zdjęcia przed wysłaniem
- Wskaźnik ładowania podczas analizy
- Wynik: imię osoby + pasek pewności (matched: true)
- Wynik: komunikat o nierozpoznaniu (matched: false)
- Obsługa błędów serwera i braku połączenia
- Automatyczny health-check serwera co 15 sekund
