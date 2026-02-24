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
