require('dotenv').config();

module.exports = {
  PORT: process.env.PORT || 8000,
  DB_PATH: process.env.DB_PATH || './db/faces.db',
  UPLOADS_TMP: process.env.UPLOADS_TMP || './uploads/tmp',
  MATCH_THRESHOLD: parseFloat(process.env.MATCH_THRESHOLD) || 0.4,
  PYTHON_PATH: process.env.PYTHON_PATH || 'python3'
};
