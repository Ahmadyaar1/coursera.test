# main.py
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import numpy as np
import tensorflow as tf
import io

# 1. Initialize App
app = FastAPI(title="GesCom Backend API")

# 2. Enable CORS (Allow your Flutter App to connect)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- GLOBAL VARIABLES ---
MODEL_PATH = "sign_model.tflite"
LABELS_PATH = "labels.txt"
IMG_SIZE = 96  # <--- CHANGE THIS if your model was trained on 128 or 192

interpreter = None
labels = []

# 3. Load Model and Labels on Startup
@app.on_event("startup")
def load_model_and_labels():
    global interpreter, labels
    try:
        # Load TFLite Model
        interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
        interpreter.allocate_tensors()
        
        # Load Labels
        with open(LABELS_PATH, "r") as f:
            labels = [line.strip() for line in f.readlines()]
            
        print(f"✅ Model loaded: {MODEL_PATH}")
        print(f"✅ Labels loaded: {labels}")
    except Exception as e:
        print(f"❌ Error loading model/labels: {e}")

# 4. Image Preprocessing
def preprocess_image(image_bytes):
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        image = image.resize((IMG_SIZE, IMG_SIZE))
        input_array = np.array(image, dtype=np.float32) / 255.0
        input_array = np.expand_dims(input_array, axis=0) # Add batch dimension
        return input_array
    except Exception as e:
        print(f"Preprocessing Error: {e}")
        return None

# 5. Prediction Endpoint
@app.post("/predict-gesture")
async def predict_gesture(file: UploadFile = File(...)):
    if interpreter is None:
        return HTTPException(status_code=500, detail="Model not loaded")

    try:
        # Read image
        image_bytes = await file.read()
        
        # Preprocess
        input_data = preprocess_image(image_bytes)
        if input_data is None:
            return HTTPException(status_code=400, detail="Invalid image")

        # Run Inference
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()
        
        output_data = interpreter.get_tensor(output_details[0]['index'])
        
        # Get Result
        predictions = output_data[0]
        predicted_index = np.argmax(predictions)
        confidence = float(predictions[predicted_index])
        detected_label = labels[predicted_index] if predicted_index < len(labels) else "Unknown"

        return {
            "status": "success",
            "sign_detected": detected_label,
            "confidence": confidence
        }
    except Exception as e:
        print(f"Prediction Error: {e}")
        return HTTPException(status_code=500, detail=str(e))

@app.get("/")
def home():
    return {"message": "GesCom Backend is Running!"}