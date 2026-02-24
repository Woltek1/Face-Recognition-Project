# Backend - Terminal Commands Cheat Sheet

Quick reference guide for all terminal commands needed to work with the Face Recognition backend.

---

## 📦 Initial Setup (One-time)

### Install Dependencies

```bash
# Install Node.js packages
npm install

# Install Python packages
pip3 install -r requirements.txt

# Install tf-keras (Mac users with TensorFlow 2.20+)
pip3 install tf-keras
```

### Configure Environment

```bash
# Copy environment template (already done if using setup script)
cp .env.example .env

# Edit if needed
nano .env
```

---

## 🚀 Starting & Stopping Server

### Start Server

```bash
node server.js
```

Expected output:
```
Database initialized successfully
Server running on http://0.0.0.0:8000
Match threshold: 0.4
```

### Stop Server

Press `Ctrl+C` in the terminal where server is running

### Restart Server

```bash
# Stop with Ctrl+C, then:
node server.js
```

### Check if Server is Running

```bash
curl http://localhost:8000/api/health
```

Should return: `{"status":"ok"}`

### Find Process on Port 8000

```bash
lsof -i :8000
```

### Kill Server Process

```bash
# Kill by port
lsof -ti:8000 | xargs kill

# Or kill all Node processes
killall node
```

---

## 👤 Managing Persons

### Add Person Manually

```bash
curl -X POST http://localhost:8000/api/persons \
  -F "name=Jan Kowalski" \
  -F "image=@path/to/photo.jpg"
```

**Example with specific path:**
```bash
curl -X POST http://localhost:8000/api/persons \
  -F "name=Anna Nowak" \
  -F "image=@/Users/jakub/Desktop/anna.jpg"
```

**Response:**
```json
{"id":1,"name":"Jan Kowalski","message":"Person added successfully"}
```

---

## 🖼️ Recognizing Faces

### Recognize Face in Image

```bash
curl -X POST http://localhost:8000/api/recognize \
  -F "image=@path/to/photo.jpg"
```

**Example:**
```bash
curl -X POST http://localhost:8000/api/recognize \
  -F "image=@test_face.jpg"
```

**Response (matched):**
```json
{"matched":true,"person":"Jan Kowalski","confidence":0.91}
```

**Response (not matched):**
```json
{"matched":false,"person":null,"confidence":0.0}
```

### Recognize with Pretty Output (requires jq)

```bash
curl -s -X POST http://localhost:8000/api/recognize \
  -F "image=@test_face.jpg" | jq .
```

Install jq if needed:
```bash
brew install jq
```

---

## 📥 Importing Dataset

### Import Entire Dataset

```bash
node import_dataset.js --path /path/to/dataset
```

**Example:**
```bash
node import_dataset.js --path ./dataset
```

### Create Test Dataset

```bash
# Create folder structure
mkdir -p test_dataset/Person_1
mkdir -p test_dataset/Person_2

# Copy images
cp photo1.jpg test_dataset/Person_1/face1.jpg
cp photo2.jpg test_dataset/Person_1/face2.jpg
cp photo3.jpg test_dataset/Person_2/face1.jpg

# Import
node import_dataset.js --path test_dataset
```

### Import from Downloaded Kaggle Dataset

```bash
# After downloading and extracting from Kaggle
node import_dataset.js --path ~/Downloads/face-recognition-dataset/cropped_faces
```

**Expected output:**
```
Starting dataset import from: test_dataset
Found 2 persons in dataset

Processing Person_1 (2 images)...
  ✓ Person_1: 2 processed, 0 failed

Processing Person_2 (1 images)...
  ✓ Person_2: 1 processed, 0 failed

=== Import Complete ===
Total processed: 3
Total failed: 0
Persons in database: 2
```

### Stop Import Mid-Process

Press `Ctrl+C` - already processed data will be saved in database

---

## 🗄️ Database Operations

### View Database Contents

```bash
node verify_db.js
```

**Output:**
```
📊 Database Schema:

Table: persons
  - id (INTEGER)
  - name (TEXT)
  - source_dataset (TEXT)
  - created_at (DATETIME)

Table: face_embeddings
  - id (INTEGER)
  - person_id (INTEGER)
  - embedding (TEXT)
  - created_at (DATETIME)

📈 Current Data:
  Persons: 5
  Embeddings: 12

👥 Sample persons:
  [1] Test Person 1 (manual)
  [2] Test Person 2 (manual)
  [3] Jan Kowalski (./dataset)
  [4] Anna Nowak (./dataset)
  [5] Piotr Wiśniewski (./dataset)

✅ Task A-3: Database schema is correct!
```

### Backup Database

```bash
cp db/faces.db db/faces.db.backup
```

### Restore Database from Backup

```bash
cp db/faces.db.backup db/faces.db
```

### Delete Database (Start Fresh)

```bash
rm db/faces.db
# Restart server - it will create new empty database
```

### Direct SQLite Query (Advanced)

```bash
# Install sqlite3 if needed
brew install sqlite3

# Open database
sqlite3 db/faces.db

# Example queries (inside sqlite3)
SELECT * FROM persons;
SELECT COUNT(*) FROM face_embeddings;
.exit
```

---

## 🧪 Testing

### Run All Tests

```bash
./run_all_tests.sh
```

### Run Individual Tests

```bash
# Test /api/recognize
./test_a5.sh

# Test /api/persons
./test_a6.sh

# Test CORS and error handling
./test_a7.sh
```

### Make Scripts Executable (if needed)

```bash
chmod +x run_all_tests.sh test_a5.sh test_a6.sh test_a7.sh
```

---

## 🔍 Debugging

### View Server Logs in Real-Time

Server logs appear in the terminal where you run `node server.js`

### Test Python Script Directly

```bash
python3 face_service.py --image test_face.jpg --mode extract
```

**Expected output:**
```json
{"success":true,"embedding":[0.123,-0.456,0.789,...]}
```

### Check Python Version

```bash
python3 --version
```

Should be 3.10 or higher

### Check Node Version

```bash
node --version
```

Should be 20.x or higher

### List Installed Python Packages

```bash
pip3 list | grep -E 'deepface|tensorflow|pillow|numpy'
```

### View Environment Variables

```bash
cat .env
```

---

## 📊 Monitoring & Statistics

### Count Persons in Database

```bash
echo "SELECT COUNT(*) FROM persons;" | sqlite3 db/faces.db
```

### Count Embeddings in Database

```bash
echo "SELECT COUNT(*) FROM face_embeddings;" | sqlite3 db/faces.db
```

### List All Persons

```bash
echo "SELECT id, name FROM persons;" | sqlite3 db/faces.db
```

### Check Database Size

```bash
ls -lh db/faces.db
```

### Check Temporary Upload Folder

```bash
ls -la uploads/tmp/
```

Should be empty when server is idle (auto-cleanup)

---

## 🧹 Cleanup

### Clear Temporary Files

```bash
rm -rf uploads/tmp/*
```

### Clear Test Datasets

```bash
rm -rf test_dataset/
rm -rf small_dataset/
```

### Remove Node Modules (if reinstalling)

```bash
rm -rf node_modules/
npm install
```

### Clear Python Cache

```bash
find . -type d -name "__pycache__" -exec rm -r {} +
find . -type f -name "*.pyc" -delete
```

---

## 🎯 Common Workflows

### Complete Setup (First Time)

```bash
# 1. Install dependencies
npm install
pip3 install -r requirements.txt
pip3 install tf-keras

# 2. Start server
node server.js

# 3. In new terminal: test health
curl http://localhost:8000/api/health

# 4. Add test person
curl -X POST http://localhost:8000/api/persons \
  -F "name=Test Person" \
  -F "image=@test_face.jpg"

# 5. Try recognition
curl -X POST http://localhost:8000/api/recognize \
  -F "image=@test_face.jpg"
```

### Daily Development Workflow

```bash
# 1. Start server
node server.js

# 2. Make changes to code
# 3. Stop server (Ctrl+C)
# 4. Restart server
node server.js

# 5. Test changes
curl -X POST http://localhost:8000/api/recognize \
  -F "image=@test_face.jpg"
```

### Import Dataset & Test Recognition

```bash
# 1. Start server
node server.js

# 2. In new terminal: import dataset
node import_dataset.js --path ./dataset

# 3. Verify import
node verify_db.js

# 4. Test recognition
curl -X POST http://localhost:8000/api/recognize \
  -F "image=@someone_from_dataset.jpg"
```

### Backup Before Major Changes

```bash
# 1. Stop server (Ctrl+C)

# 2. Backup database
cp db/faces.db db/faces.db.backup-$(date +%Y%m%d)

# 3. Restart and proceed
node server.js
```

---

## 🔧 Troubleshooting Commands

### Server Won't Start - Port in Use

```bash
# Find what's using port 8000
lsof -i :8000

# Kill it
lsof -ti:8000 | xargs kill

# Try starting again
node server.js
```

### Python Script Fails

```bash
# Test Python directly
python3 face_service.py --help

# Check if deepface installed
pip3 show deepface

# Reinstall if needed
pip3 install --upgrade deepface tensorflow
```

### Database Corrupted

```bash
# Stop server
# Delete database
rm db/faces.db

# Restart server (creates new db)
node server.js

# Re-import dataset
node import_dataset.js --path ./dataset
```

### Can't Connect from Other Devices

```bash
# Find your local IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Example: 192.168.1.100
# Then from other device use:
# http://192.168.1.100:8000/api/health
```

---

## 📱 Testing from Mobile/Desktop Apps

When testing with mobile or desktop apps, replace `localhost` with your Mac's IP address:

```bash
# Find your IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Example output: 192.168.1.100
```

Then apps should connect to: `http://192.168.1.100:8000/api`

---

## 🎓 Quick Reference

| Task | Command |
|------|---------|
| Start server | `node server.js` |
| Stop server | `Ctrl+C` |
| Health check | `curl http://localhost:8000/api/health` |
| Add person | `curl -X POST http://localhost:8000/api/persons -F "name=Name" -F "image=@photo.jpg"` |
| Recognize face | `curl -X POST http://localhost:8000/api/recognize -F "image=@photo.jpg"` |
| Import dataset | `node import_dataset.js --path ./dataset` |
| View database | `node verify_db.js` |
| Backup database | `cp db/faces.db db/faces.db.backup` |
| Run tests | `./run_all_tests.sh` |

---

## 💡 Tips

- **Always have server running** when making API requests
- **Use absolute paths** for images if relative paths don't work
- **Restart server** after changing `.env` file
- **Import takes time** - be patient with large datasets
- **Backup before experiments** - database operations can't be undone
- **Check server logs** when debugging - errors appear there

---

## 🆘 Need Help?

1. Check server logs in terminal where `node server.js` is running
2. Run `./run_all_tests.sh` to verify everything works
3. Check database with `node verify_db.js`
4. Test Python directly: `python3 face_service.py --image test.jpg --mode extract`
5. Review this cheat sheet for correct command syntax

---

**Last Updated:** February 2026  
**For:** Face Recognition Project - Backend (Person A)
