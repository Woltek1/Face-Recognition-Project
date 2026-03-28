import os
from PIL import Image

dataset_path = "./SmallDataset"

for person_name in os.listdir(dataset_path):
    person_path = os.path.join(dataset_path, person_name)
    if not os.path.isdir(person_path):
        continue
    print(f"Sprawdzanie osoby: {person_name}")
    
    for file_name in os.listdir(person_path):
        file_path = os.path.join(person_path, file_name)
        try:
            img = Image.open(file_path)
            img.verify()  # Sprawdza czy plik obrazu nie jest uszkodzony
            print(f"  ✓ {file_name} OK")
        except Exception as e:
            print(f"  ⚠ {file_name} Błąd: {e}")