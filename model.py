import tensorflow as tf
import numpy as np
from PIL import Image
import io
import os

# Placeholder class names - update these with your actual dataset labels!
CLASS_NAMES = ["Healthy", "Rust", "Powdery Mildew", "Bacterial Spot"] 

MODEL_PATH = "plant_model.h5"
model = None

def load_model():
    global model
    if os.path.exists(MODEL_PATH):
        model = tf.keras.models.load_model(MODEL_PATH)
        print(f"Loaded model from {MODEL_PATH}")
    else:
        print(f"Model file {MODEL_PATH} not found. Please run train_model.py first.")

# Initial load attempt
load_model()

def predict_image(image_bytes):
    global model
    if model is None:
        return {"error": "Model not loaded. Please ensure plant_model.h5 exists."}
    
    # Load and preprocess the image
    img = Image.open(io.BytesIO(image_bytes))
    img = img.resize((224, 224))
    img_array = np.array(img) / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    
    # Predict
    predictions = model.predict(img_array)
    score = tf.nn.softmax(predictions[0])
    
    class_index = np.argmax(predictions[0])
    
    # Handle unknown classes with basic indices if CLASS_NAMES is shorter
    if class_index < len(CLASS_NAMES):
        label = CLASS_NAMES[class_index]
    else:
        label = f"Class {class_index}"
        
    return {
        "disease": label,
        "confidence": float(np.max(predictions[0]))
    }
