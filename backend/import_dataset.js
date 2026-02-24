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
