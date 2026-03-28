import cv2
import os
from deepface import DeepFace
try:
    result = DeepFace.represent(
        img_path='./SmallDataset/Akshay Kumar/Akshay Kumar_0.jpg',
        model_name='Facenet512',
        enforce_detection=False,
        detector_backend='mtcnn'
    )
    print('DeepFace result:', result[0]['embedding'][:5])
except Exception as e:
    print('DeepFace error:', e)

path = './SmallDataset/Akshay Kumar/Akshay Kumar_0.jpg'
img = cv2.imread(path)
print('Image loaded:', img is not None)
if img is not None:
    print('Shape:', img.shape)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    faces = cascade.detectMultiScale(gray, 1.1, 4)
    print('Faces found by opencv cascade:', len(faces))

try:
    import retina_face
    print('retina_face: OK')
except:
    print('retina_face: NOT INSTALLED')

try:
    import mtcnn
    print('mtcnn: OK')
except:
    print('mtcnn: NOT INSTALLED')