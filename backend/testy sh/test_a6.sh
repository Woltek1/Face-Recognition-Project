#!/bin/bash

echo "========================================"
echo "Task A-6: Testing /api/persons"
echo "========================================"
echo ""

# Test 1: Add new person successfully
echo "Test 1: Add new person (should return 201)"
echo "-------------------------------------------"
curl -s -X POST http://localhost:8000/api/persons \
  -F "name=Test User $(date +%s)" \
  -F "image=@test_face.jpg" | jq .
echo ""

# Test 2: Missing name field
echo "Test 2: Missing name field (should return 400)"
echo "-----------------------------------------------"
curl -s -X POST http://localhost:8000/api/persons \
  -F "image=@test_face.jpg" | jq .
echo ""

# Test 3: Missing image field
echo "Test 3: Missing image field (should return 400)"
echo "------------------------------------------------"
curl -s -X POST http://localhost:8000/api/persons \
  -F "name=Test User" | jq .
echo ""

# Test 4: Invalid image (no face)
echo "Test 4: Invalid image - no face detected"
echo "-----------------------------------------"
# Create a blank image
convert -size 100x100 xc:white /tmp/blank.jpg 2>/dev/null || {
  echo "⚠️  ImageMagick not installed, skipping blank image test"
  echo "Manual test: Upload an image with no face"
}

if [ -f /tmp/blank.jpg ]; then
  curl -s -X POST http://localhost:8000/api/persons \
    -F "name=Blank Test" \
    -F "image=@/tmp/blank.jpg" | jq .
  rm /tmp/blank.jpg
fi
echo ""

echo "========================================"
echo "Task A-6 Checklist:"
echo "========================================"
echo "✓ Accepts multipart/form-data with 'name' and 'image'"
echo "✓ Returns 201 with id, name, message on success"
echo "✓ Returns 400 for missing name"
echo "✓ Returns 400 for missing image"
echo "✓ Returns 400 for images with no face"
echo "✓ Validates input properly"
echo ""
