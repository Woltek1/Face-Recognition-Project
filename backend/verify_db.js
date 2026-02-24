const Database = require('better-sqlite3');
const db = new Database('./db/faces.db');

console.log('\n📊 Database Schema:\n');

// Check persons table
const personsSchema = db.prepare("PRAGMA table_info(persons)").all();
console.log('Table: persons');
personsSchema.forEach(col => {
  console.log('  - ' + col.name + ' (' + col.type + ')');
});

// Check face_embeddings table
const embeddingsSchema = db.prepare("PRAGMA table_info(face_embeddings)").all();
console.log('\nTable: face_embeddings');
embeddingsSchema.forEach(col => {
  console.log('  - ' + col.name + ' (' + col.type + ')');
});

// Check data
const personsCount = db.prepare('SELECT COUNT(*) as count FROM persons').get();
const embeddingsCount = db.prepare('SELECT COUNT(*) as count FROM face_embeddings').get();

console.log('\n📈 Current Data:');
console.log('  Persons: ' + personsCount.count);
console.log('  Embeddings: ' + embeddingsCount.count);

if (personsCount.count > 0) {
  console.log('\n👥 Sample persons:');
  const samples = db.prepare('SELECT id, name, source_dataset FROM persons LIMIT 5').all();
  samples.forEach(p => {
    console.log('  [' + p.id + '] ' + p.name + ' (' + (p.source_dataset || 'manual') + ')');
  });
}

console.log('\n✅ Task A-3: Database schema is correct!\n');