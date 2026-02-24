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
