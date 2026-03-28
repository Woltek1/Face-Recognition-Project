const { spawn } = require('child_process');

const imagePath = "./SmallDataset/Akshay_Kumar/Akshay_Kumar_0.jpg"; // zmień jeśli potrzebne
const PYTHON_PATH = "python"; // lub pełna ścieżka do Pythona

const py = spawn(PYTHON_PATH, ['face_service.py', '--image', imagePath, '--mode', 'extract']);

py.stdout.on('data', (data) => { console.log("STDOUT:", data.toString()); });
py.stderr.on('data', (data) => { console.error("STDERR:", data.toString()); });

py.on('close', (code) => {
  console.log("Process exited with code", code);
});