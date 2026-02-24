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

function callFaceService(imagePath, mode, personId = null) {
  return new Promise((resolve, reject) => {
    const args = ['face_service.py', '--image', imagePath, '--mode', mode];
    if (personId) {
      args.push('--person_id', personId.toString());
    }
    
    console.log('🐍 Calling Python with:', config.PYTHON_PATH, args); // DODAJ TO
    
    const py = spawn(config.PYTHON_PATH, args);
    let output = '';
    let errorOutput = '';

    py.stdout.on('data', (data) => { 
      console.log('📤 Python stdout:', data.toString()); // DODAJ TO
      output += data.toString(); 
    });
    
    py.stderr.on('data', (data) => { 
      console.log('⚠️ Python stderr:', data.toString()); // DODAJ TO
      errorOutput += data.toString(); 
    });

    py.on('close', (code) => {
      console.log('🔚 Python exit code:', code); // DODAJ TO
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
  console.log('🔵 /recognize endpoint hit!');
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
  console.log('🟢 /persons endpoint hit!');
  if (!req.file) {
    return res.status(400).json({ error: 'No image file provided' });
  }

  const { name } = req.body;
  console.log('📝 Adding person:', name);
  if (!name) {
    fs.unlinkSync(req.file.path);
    return res.status(400).json({ error: 'Name is required' });
  }

  const imagePath = req.file.path;
  console.log('📁 Image path:', imagePath);

  try {
    console.log('🐍 About to call Python...');
    const result = await callFaceService(imagePath, 'extract');
    console.log('✅ Python returned:', result);
    
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
