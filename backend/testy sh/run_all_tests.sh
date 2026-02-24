#!/bin/bash

echo "========================================"
echo "Backend Tasks A-5, A-6, A-7: Full Test Suite"
echo "========================================"
echo ""
echo "Prerequisites:"
echo "  - Server must be running: node server.js"
echo "  - test_face.jpg must exist in current directory"
echo "  - jq must be installed (brew install jq)"
echo ""
read -p "Press Enter to start tests (Ctrl+C to cancel)..."
echo ""

# Check if server is running
if ! curl -s http://localhost:8000/api/health > /dev/null 2>&1; then
  echo "❌ Error: Server is not running on port 8000"
  echo "Please start server with: node server.js"
  exit 1
fi

# Check if test image exists
if [ ! -f test_face.jpg ]; then
  echo "❌ Error: test_face.jpg not found"
  echo "Please provide a test face image"
  exit 1
fi

echo "✓ Server is running"
echo "✓ Test image found"
echo ""

# Run Task A-5 tests
bash test_a5.sh

# Run Task A-6 tests
bash test_a6.sh

# Run Task A-7 tests
bash test_a7.sh

echo ""
echo "========================================"
echo "All Tests Complete!"
echo "========================================"
echo ""
echo "Summary:"
echo "  Task A-5: /api/recognize endpoint - TESTED"
echo "  Task A-6: /api/persons endpoint - TESTED"
echo "  Task A-7: CORS and error handling - TESTED"
echo ""
echo "Review the output above for any failures."
echo "All tasks should now be complete!"
echo ""
