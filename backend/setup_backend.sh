#!/bin/bash

# Backend setup script for Face Recognition Project
echo "Creating backend structure..."

# Create directories
mkdir -p db routes uploads/tmp

# Create package.json
cat > package.json << 'EOF'
{
  "name": "face-recognition-backend",
  "version": "1.0.0",
  "description": "Backend for face recognition system using Express.js and DeepFace",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "import": "node import_dataset.js"
  },
  "keywords": ["face-recognition", "deepface", "express"],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "express": "4.18.2",
    "cors": "2.8.5",
    "multer": "1.4.5-lts.1",
    "better-sqlite3": "9.4.3",
    "dotenv": "16.3.1"
  }
}
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
deepface==0.0.92
tensorflow==2.20.0
pillow==11.0.0
numpy==1.26.4
EOF

# Create .env
cat > .env << 'EOF'
PORT=8000
DB_PATH=./db/faces.db
UPLOADS_TMP=./uploads/tmp
MATCH_THRESHOLD=0.4
PYTHON_PATH=python3
EOF

# Create config.js
cat > config.js << 'EOF'
require('dotenv').config();

module.exports = {
  PORT: process.env.PORT || 8000,
  DB_PATH: process.env.DB_PATH || './db/faces.db',
  UPLOADS_TMP: process.env.UPLOADS_TMP || './uploads/tmp',
  MATCH_THRESHOLD: parseFloat(process.env.MATCH_THRESHOLD) || 0.4,
  PYTHON_PATH: process.env.PYTHON_PATH || 'python3'
};
EOF

# Create server.js
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const config = require('./config');
const apiRoutes = require('./routes/api');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Ensure uploads/tmp directory exists
if (!fs.existsSync(config.UPLOADS_TMP)) {
  fs.mkdirSync(config.UPLOADS_TMP, { recursive: true });
}

// Initialize database
require('./db/database');

// Routes
app.use('/api', apiRoutes);

// Start server
app.listen(config.PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${config.PORT}`);
  console.log(`Match threshold: ${config.MATCH_THRESHOLD}`);
});
EOF

# Create db/database.js
cat > db/database.js << 'EOF'
const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const config = require('../config');

// Ensure db directory exists
const dbDir = path.dirname(config.DB_PATH);
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

// Initialize database connection
const db = new Database(config.DB_PATH);

// Enable foreign keys
db.pragma('foreign_keys = ON');

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS persons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    source_dataset TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS face_embeddings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id INTEGER NOT NULL,
    embedding TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE CASCADE
  );
`);

console.log('Database initialized successfully');

module.exports = db;
EOF

# Create routes/api.js
cat > routes/api.js << 'EOFAPI'
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const db = require('../db/database');
const config = require('../config');

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  dest: config.UPLOADS_TMP,
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG and PNG images are allowed'));
    }
  },
  limits: { fileSize: 10 * 1024 * 1024 }
});

// Helper function to call Python face service
function callFaceService(imagePath, mode, personId = null) {
  return new Promise((resolve, reject) => {
    const args = ['face_service.py', '--image', imagePath, '--mode', mode];
    if (personId) {
      args.push('--person_id', personId.toString());
    }
    
    const py = spawn(config.PYTHON_PATH, args);
    let output = '';
    let errorOutput = '';

    py.stdout.on('data', (data) => { output += data.toString(); });
    py.stderr.on('data', (data) => { errorOutput += data.toString(); });

    py.on('close', (code) => {
      if (code !== 0) {
        return reject(new Error(errorOutput || 'Python script failed'));
      }
      try {
        resolve(JSON.parse(output));
      } catch (e) {
        reject(new Error('Invalid JSON from Python script'));
      }
    });
  });
}

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// POST /api/recognize
router.post('/recognize', upload.single('image'), async (req, res) => {
  const startTime = Date.now();
  
  if (!req.file) {
    return res.status(400).json({ error: 'No image file provided' });
  }

  const imagePath = req.file.path;

  try {
    const embeddings = db.prepare(`
      SELECT fe.embedding, p.name, fe.person_id
      FROM face_embeddings fe
      JOIN persons p ON fe.person_id = p.id
    `).all();

    if (embeddings.length === 0) {
      fs.unlinkSync(imagePath);
      return res.json({
        matched: false,
        person: null,
        confidence: 0.0
      });
    }

    const result = await callFaceService(imagePath, 'extract');
    
    if (!result.success) {
      fs.unlinkSync(imagePath);
      return res.status(400).json({ error: result.error || 'No face detected in image' });
    }

    const uploadedEmbedding = result.embedding;
    let bestMatch = null;
    let bestDistance = Infinity;

    for (const row of embeddings) {
      const dbEmbedding = JSON.parse(row.embedding);
      const distance = cosineSimilarity(uploadedEmbedding, dbEmbedding);
      
      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = row.name;
      }
    }

    fs.unlinkSync(imagePath);

    const processingTime = Date.now() - startTime;
    const matched = bestDistance < config.MATCH_THRESHOLD;
    
    console.log(`[${new Date().toISOString()}] Recognize request - Matched: ${matched}, Person: ${matched ? bestMatch : 'None'}, Distance: ${bestDistance.toFixed(4)}, Time: ${processingTime}ms`);

    if (matched) {
      res.json({
        matched: true,
        person: bestMatch,
        confidence: parseFloat((1 - bestDistance).toFixed(2))
      });
    } else {
      res.json({
        matched: false,
        person: null,
        confidence: 0.0
      });
    }

  } catch (error) {
    console.error('Error in /recognize:', error);
    if (fs.existsSync(imagePath)) {
      fs.unlinkSync(imagePath);
    }
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
});

// POST /api/persons
router.post('/persons', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No image file provided' });
  }

  const { name } = req.body;
  if (!name) {
    fs.unlinkSync(req.file.path);
    return res.status(400).json({ error: 'Name is required' });
  }

  const imagePath = req.file.path;

  try {
    const result = await callFaceService(imagePath, 'extract');
    
    if (!result.success) {
      fs.unlinkSync(imagePath);
      return res.status(400).json({ error: result.error || 'No face detected in image' });
    }

    const insertPerson = db.prepare('INSERT INTO persons (name, source_dataset) VALUES (?, ?)');
    const personResult = insertPerson.run(name, 'manual');
    const personId = personResult.lastInsertRowid;

    const insertEmbedding = db.prepare('INSERT INTO face_embeddings (person_id, embedding) VALUES (?, ?)');
    insertEmbedding.run(personId, JSON.stringify(result.embedding));

    fs.unlinkSync(imagePath);

    res.status(201).json({
      id: personId,
      name: name,
      message: 'Person added successfully'
    });

  } catch (error) {
    console.error('Error in /persons:', error);
    if (fs.existsSync(imagePath)) {
      fs.unlinkSync(imagePath);
    }
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
});

function cosineSimilarity(vec1, vec2) {
  let dotProduct = 0;
  let norm1 = 0;
  let norm2 = 0;

  for (let i = 0; i < vec1.length; i++) {
    dotProduct += vec1[i] * vec2[i];
    norm1 += vec1[i] * vec1[i];
    norm2 += vec2[i] * vec2[i];
  }

  const similarity = dotProduct / (Math.sqrt(norm1) * Math.sqrt(norm2));
  return 1 - similarity;
}

module.exports = router;
EOFAPI

# Create face_service.py
cat > face_service.py << 'EOFPY'
#!/usr/bin/env python3
"""
Face Service - DeepFace integration for face recognition
"""

import sys
import json
import argparse
from deepface import DeepFace

MODEL_NAME = "Facenet512"

def extract_embedding(image_path):
    try:
        result = DeepFace.represent(
            img_path=image_path,
            model_name=MODEL_NAME,
            enforce_detection=True,
            detector_backend='opencv'
        )
        
        if len(result) == 0:
            return {
                "success": False,
                "error": "No face detected in image"
            }
        
        embedding = result[0]["embedding"]
        
        return {
            "success": True,
            "embedding": embedding
        }
        
    except ValueError as e:
        return {
            "success": False,
            "error": "No face detected in image"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

def main():
    parser = argparse.ArgumentParser(description='Face recognition service')
    parser.add_argument('--image', required=True, help='Path to image file')
    parser.add_argument('--mode', required=True, choices=['extract', 'recognize'])
    parser.add_argument('--person_id', type=int, help='Person ID')
    
    args = parser.parse_args()
    
    result = extract_embedding(args.image)
    print(json.dumps(result))
    
    if not result['success']:
        sys.exit(1)

if __name__ == "__main__":
    main()
EOFPY

# Create import_dataset.js
cat > import_dataset.js << 'EOFIMPORT'
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const db = require('./db/database');
const config = require('./config');

function callFaceService(imagePath, mode) {
  return new Promise((resolve, reject) => {
    const py = spawn(config.PYTHON_PATH, ['face_service.py', '--image', imagePath, '--mode', mode]);
    let output = '';
    let errorOutput = '';

    py.stdout.on('data', (data) => { output += data.toString(); });
    py.stderr.on('data', (data) => { errorOutput += data.toString(); });

    py.on('close', (code) => {
      if (code !== 0) {
        return reject(new Error(errorOutput || 'Python script failed'));
      }
      try {
        resolve(JSON.parse(output));
      } catch (e) {
        reject(new Error('Invalid JSON from Python script'));
      }
    });
  });
}

async function importDataset(datasetPath) {
  console.log(`Starting dataset import from: ${datasetPath}`);
  
  if (!fs.existsSync(datasetPath)) {
    console.error(`Error: Dataset path does not exist: ${datasetPath}`);
    process.exit(1);
  }

  const persons = fs.readdirSync(datasetPath, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

  console.log(`Found ${persons.length} persons in dataset`);

  let totalProcessed = 0;
  let totalFailed = 0;

  for (const personName of persons) {
    const personDir = path.join(datasetPath, personName);
    const images = fs.readdirSync(personDir)
      .filter(file => /\.(jpg|jpeg|png)$/i.test(file));

    console.log(`\nProcessing ${personName} (${images.length} images)...`);

    const insertPerson = db.prepare('INSERT INTO persons (name, source_dataset) VALUES (?, ?)');
    const personResult = insertPerson.run(personName, datasetPath);
    const personId = personResult.lastInsertRowid;

    let personProcessed = 0;
    let personFailed = 0;

    for (const imageFile of images) {
      const imagePath = path.join(personDir, imageFile);
      
      try {
        const result = await callFaceService(imagePath, 'extract');
        
        if (result.success) {
          const insertEmbedding = db.prepare('INSERT INTO face_embeddings (person_id, embedding) VALUES (?, ?)');
          insertEmbedding.run(personId, JSON.stringify(result.embedding));
          
          personProcessed++;
          totalProcessed++;
        } else {
          console.log(`  ⚠ Skipped ${imageFile}: ${result.error}`);
          personFailed++;
          totalFailed++;
        }
      } catch (error) {
        console.log(`  ⚠ Error processing ${imageFile}: ${error.message}`);
        personFailed++;
        totalFailed++;
      }
    }

    console.log(`  ✓ ${personName}: ${personProcessed} processed, ${personFailed} failed`);
  }

  console.log(`\n=== Import Complete ===`);
  console.log(`Total processed: ${totalProcessed}`);
  console.log(`Total failed: ${totalFailed}`);
  console.log(`Persons in database: ${persons.length}`);
}

const args = process.argv.slice(2);
let datasetPath = null;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--path' && i + 1 < args.length) {
    datasetPath = args[i + 1];
    break;
  }
}

if (!datasetPath) {
  console.error('Usage: node import_dataset.js --path <dataset_path>');
  process.exit(1);
}

importDataset(datasetPath)
  .then(() => {
    console.log('Import completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Import failed:', error);
    process.exit(1);
  });
EOFIMPORT

# Create .gitkeep in uploads/tmp
touch uploads/tmp/.gitkeep

echo ""
echo "✅ Backend structure created successfully!"
echo ""
echo "Next steps:"
echo "1. npm install"
echo "2. pip3 install -r requirements.txt"
echo "3. node server.js"
