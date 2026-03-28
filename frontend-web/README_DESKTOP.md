# Aplikacja Desktopowa — System Rozpoznawania Twarzy

## Wymagania systemowe

- Python 3.10+
- pip

## Instalacja

```bash
pip install -r requirements.txt
```

## Uruchomienie

```bash
python main.py
```

## Zmiana adresu serwera

Edytuj plik `config.json` — bez dotykania kodu:

```json
{
  "api_url": "http://ADRES_IP:8000/api"
}
```

Plik jest wczytywany przy każdym starcie aplikacji.

## Obsługa błędów

| Sytuacja | Komunikat |
|---|---|
| Brak połączenia z serwerem | "Nie można połączyć z serwerem. Sprawdź adres w config.json." |
| Timeout (>30s) | "Przekroczono czas oczekiwania (30s). Sprawdź połączenie." |
| Brak twarzy na zdjęciu | Wyświetlany komunikat z serwera (pole `error`) |
| Błąd 400/500 | Wyświetlany komunikat z pola `error` z odpowiedzi JSON |
