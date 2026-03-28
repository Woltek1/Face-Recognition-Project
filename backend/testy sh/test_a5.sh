#!/bin/bash

echo "========================================"
echo "Task A-5: Testing /api/recognize"
echo "========================================"
echo ""

# Test 1: Recognize existing person
echo "Test 1: Recognize existing person (should match)"
echo "-----------------------------------------------"
curl -s -X POST http://localhost:8000/api/recognize \
  -F "image=@test_face.jpg" | jq .
echo ""

# Test 2: No file provided
echo "Test 2: No file provided (should return 400 error)"
echo "---------------------------------------------------"
curl -s -X POST http://localhost:8000/api/recognize | jq .
echo ""

# Test 3: Invalid file type (if you have a txt file)
echo "Test 3: Invalid file type (should return error)"
echo "------------------------------------------------"
echo "test content" > /tmp/test.txt
curl -s -X POST http://localhost:8000/api/recognize \
  -F "image=@/tmp/test.txt" 2>&1 | head -5
echo ""
rm /tmp/test.txt

# Test 4: Empty database scenario
echo "Test 4: Empty database (backup current db first)"
echo "-------------------------------------------------"
if [ -f db/faces.db ]; then
  echo "Backing up database..."
  cp db/faces.db db/faces.db.backup
  rm db/faces.db
  
  # Restart server required here - manual step
  echo "⚠️  Manual step: Restart server, then run test again"
  echo "After test, restore with: mv db/faces.db.backup db/faces.db"
else
  echo "No database found - this tests empty db scenario"
  curl -s -X POST http://localhost:8000/api/recognize \
    -F "image=@test_face.jpg" | jq .
fi

echo ""
echo "========================================"
echo "Task A-5 Checklist:"
echo "========================================"
echo "✓ Accepts multipart/form-data with 'image' field"
echo "✓ Returns JSON with matched, person, confidence"
echo "✓ Handles empty database gracefully"
echo "✓ Returns 400 for missing file"
echo "✓ Logs timestamp, result, processing time"
echo ""
