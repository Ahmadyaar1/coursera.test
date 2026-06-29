# # main.py
# from fastapi import FastAPI, File, UploadFile, HTTPException
# from fastapi.middleware.cors import CORSMiddleware
# from PIL import Image
# import numpy as np
# import tensorflow as tf
# import io

# # 1. Initialize App
# app = FastAPI(title="GesCom Backend API")

# # 2. Enable CORS (Allow your Flutter App to connect)
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"], 
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# # --- GLOBAL VARIABLES ---
# MODEL_PATH = "sign_model.tflite"
# LABELS_PATH = "labels.txt"
# IMG_SIZE = 96  # <--- CHANGE THIS if your model was trained on 128 or 192

# interpreter = None
# labels = []

# # 3. Load Model and Labels on Startup
# @app.on_event("startup")
# def load_model_and_labels():
#     global interpreter, labels
#     try:
#         # Load TFLite Model
#         interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
#         interpreter.allocate_tensors()
        
#         # Load Labels
#         with open(LABELS_PATH, "r") as f:
#             labels = [line.strip() for line in f.readlines()]
            
#         print(f"✅ Model loaded: {MODEL_PATH}")
#         print(f"✅ Labels loaded: {labels}")
#     except Exception as e:
#         print(f"❌ Error loading model/labels: {e}")

# # 4. Image Preprocessing
# def preprocess_image(image_bytes):
#     try:
#         image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
#         image = image.resize((IMG_SIZE, IMG_SIZE))
#         input_array = np.array(image, dtype=np.float32) / 255.0
#         input_array = np.expand_dims(input_array, axis=0) # Add batch dimension
#         return input_array
#     except Exception as e:
#         print(f"Preprocessing Error: {e}")
#         return None

# # 5. Prediction Endpoint
# @app.post("/predict-gesture")
# async def predict_gesture(file: UploadFile = File(...)):
#     if interpreter is None:
#         return HTTPException(status_code=500, detail="Model not loaded")

#     try:
#         # Read image
#         image_bytes = await file.read()
        
#         # Preprocess
#         input_data = preprocess_image(image_bytes)
#         if input_data is None:
#             return HTTPException(status_code=400, detail="Invalid image")

#         # Run Inference
#         input_details = interpreter.get_input_details()
#         output_details = interpreter.get_output_details()
        
#         interpreter.set_tensor(input_details[0]['index'], input_data)
#         interpreter.invoke()
        
#         output_data = interpreter.get_tensor(output_details[0]['index'])
        
#         # Get Result
#         predictions = output_data[0]
#         predicted_index = np.argmax(predictions)
#         confidence = float(predictions[predicted_index])
#         detected_label = labels[predicted_index] if predicted_index < len(labels) else "Unknown"

#         return {
#             "status": "success",
#             "sign_detected": detected_label,
#             "confidence": confidence
#         }
#     except Exception as e:
#         print(f"Prediction Error: {e}")
#         return HTTPException(status_code=500, detail=str(e))

# @app.get("/")
# def home():
#     return {"message": "GesCom Backend is Running!"}



# main.py

# from fastapi import FastAPI, File, UploadFile, HTTPException
# from fastapi.middleware.cors import CORSMiddleware
# from PIL import Image
# import numpy as np
# import tensorflow as tf
# tflite = tf.lite
# import io

# # ── App ───────────────────────────────────────────────────────────────────
# app = FastAPI(title="GesCom Backend API")

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# # ── Config ────────────────────────────────────────────────────────────────
# MODEL_PATH           = "sign_model.tflite"
# LABELS_PATH          = "labels.txt"
# IMG_SIZE             = 96
# CONFIDENCE_THRESHOLD = 0.6

# # ── Globals ───────────────────────────────────────────────────────────────
# interpreter    = None
# input_details  = None
# output_details = None
# labels         = []

# # ── Startup ───────────────────────────────────────────────────────────────
# @app.on_event("startup")
# def load_model_and_labels():
#     global interpreter, input_details, output_details, labels
#     try:
#         interpreter = tflite.Interpreter(model_path=MODEL_PATH)
#         interpreter.allocate_tensors()
#         input_details  = interpreter.get_input_details()
#         output_details = interpreter.get_output_details()

#         with open(LABELS_PATH, "r") as f:
#             labels = [line.strip() for line in f if line.strip()]

#         print(f"✅ Model loaded — input shape: {input_details[0]['shape']}")
#         print(f"✅ Labels loaded — {len(labels)} classes: {labels}")

#     except Exception as e:
#         print(f"❌ Startup error: {e}")
#         raise e

# # ── Preprocessing ─────────────────────────────────────────────────────────
# def preprocess_image(image_bytes: bytes):
#     image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
#     image = image.resize((IMG_SIZE, IMG_SIZE))
#     arr   = np.array(image, dtype=np.float32) / 255.0
#     return np.expand_dims(arr, axis=0)  # shape: (1, 96, 96, 3)

# # ── Predict ───────────────────────────────────────────────────────────────
# @app.post("/predict-gesture")
# async def predict_gesture(file: UploadFile = File(...)):
#     if interpreter is None:
#         raise HTTPException(status_code=500, detail="Model not loaded")

#     if file.content_type not in ["image/jpeg", "image/png", "image/jpg"]:
#         raise HTTPException(status_code=400, detail="Only JPEG/PNG accepted")

#     try:
#         image_bytes = await file.read()
#         input_data  = preprocess_image(image_bytes)

#         interpreter.set_tensor(input_details[0]['index'], input_data)
#         interpreter.invoke()

#         predictions     = interpreter.get_tensor(output_details[0]['index'])[0]
#         predicted_index = int(np.argmax(predictions))
#         confidence      = float(predictions[predicted_index])

#         # Reject low confidence
#         if confidence < CONFIDENCE_THRESHOLD:
#             return {
#                 "status":        "uncertain",
#                 "sign_detected": None,
#                 "confidence":    round(confidence, 4),
#                 "message":       "Confidence too low — adjust hand position"
#             }

#         detected_label = labels[predicted_index] if predicted_index < len(labels) else "Unknown"

#         # Top 3 predictions
#         top3_idx = np.argsort(predictions)[::-1][:3]
#         top3 = [
#             {
#                 "label":      labels[i] if i < len(labels) else "Unknown",
#                 "confidence": round(float(predictions[i]), 4)
#             }
#             for i in top3_idx
#         ]

#         return {
#             "status":        "success",
#             "sign_detected":  detected_label,
#             "confidence":     round(confidence, 4),
#             "class_index":    predicted_index,
#             "top3":           top3
#         }

#     except HTTPException:
#         raise
#     except Exception as e:
#         print(f"❌ Prediction error: {e}")
#         raise HTTPException(status_code=500, detail=str(e))

# # ── Labels ────────────────────────────────────────────────────────────────
# @app.get("/labels")
# def get_labels():
#     return {
#         "total":  len(labels),
#         "labels": {str(i): l for i, l in enumerate(labels)}
#     }

# # ── Hot Reload ────────────────────────────────────────────────────────────
# @app.post("/reload")
# def reload_model():
#     global interpreter, input_details, output_details, labels
#     try:
#         interpreter = tflite.Interpreter(model_path=MODEL_PATH)
#         interpreter.allocate_tensors()
#         input_details  = interpreter.get_input_details()
#         output_details = interpreter.get_output_details()

#         with open(LABELS_PATH, "r") as f:
#             labels = [line.strip() for line in f if line.strip()]

#         return {
#             "status":  "reloaded",
#             "classes": len(labels),
#             "labels":  labels
#         }
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

# # ── Health ────────────────────────────────────────────────────────────────
# @app.get("/")
# def home():
#     return {
#         "message":  "GesCom Backend is Running!",
#         "model":    MODEL_PATH,
#         "classes":  len(labels),
#         "img_size": IMG_SIZE
#     }













# main.py
from fastapi import FastAPI, File, UploadFile, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import numpy as np
import tensorflow as tf
tflite = tf.lite
import io

# ── App ───────────────────────────────────────────────────────────────────
app = FastAPI(title="GesCom Backend API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Config ────────────────────────────────────────────────────────────────
MODEL_PATH           = "sign_model.tflite"
LABELS_PATH          = "labels.txt"
IMG_SIZE             = 96
CONFIDENCE_THRESHOLD = 0.6
API_KEY              = "gescom-secret-2024"  # ← Change this to your own secret

# ── Globals ───────────────────────────────────────────────────────────────
interpreter    = None
input_details  = None
output_details = None
labels         = []

# ── Startup ───────────────────────────────────────────────────────────────
@app.on_event("startup")
def load_model_and_labels():
    global interpreter, input_details, output_details, labels
    try:
        interpreter = tflite.Interpreter(model_path=MODEL_PATH)
        interpreter.allocate_tensors()
        input_details  = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        with open(LABELS_PATH, "r") as f:
            labels = [line.strip() for line in f if line.strip()]

        print(f"✅ Model loaded — input shape: {input_details[0]['shape']}")
        print(f"✅ Labels loaded — {len(labels)} classes: {labels}")

    except Exception as e:
        print(f"❌ Startup error: {e}")
        raise e

# ── Preprocessing ─────────────────────────────────────────────────────────
def preprocess_image(image_bytes: bytes):
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((IMG_SIZE, IMG_SIZE))
    arr   = np.array(image, dtype=np.float32) / 255.0
    return np.expand_dims(arr, axis=0)  # shape: (1, 96, 96, 3)

# ── Predict ───────────────────────────────────────────────────────────────
@app.post("/predict-gesture")
async def predict_gesture(file: UploadFile = File(...), x_api_key: str = Header(...)):
    # ── Auth check ────────────────────────────────────────────────────────
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized: Invalid API key")

    if interpreter is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    if file.content_type not in ["image/jpeg", "image/png", "image/jpg"]:
        raise HTTPException(status_code=400, detail="Only JPEG/PNG accepted")

    try:
        image_bytes = await file.read()
        input_data  = preprocess_image(image_bytes)

        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()

        predictions     = interpreter.get_tensor(output_details[0]['index'])[0]
        predicted_index = int(np.argmax(predictions))
        confidence      = float(predictions[predicted_index])

        # Reject low confidence
        if confidence < CONFIDENCE_THRESHOLD:
            return {
                "status":        "uncertain",
                "sign_detected": None,
                "confidence":    round(confidence, 4),
                "message":       "Confidence too low — adjust hand position"
            }

        detected_label = labels[predicted_index] if predicted_index < len(labels) else "Unknown"

        # Top 3 predictions
        top3_idx = np.argsort(predictions)[::-1][:3]
        top3 = [
            {
                "label":      labels[i] if i < len(labels) else "Unknown",
                "confidence": round(float(predictions[i]), 4)
            }
            for i in top3_idx
        ]

        return {
            "status":        "success",
            "sign_detected":  detected_label,
            "confidence":     round(confidence, 4),
            "class_index":    predicted_index,
            "top3":           top3
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ── Labels ────────────────────────────────────────────────────────────────
@app.get("/labels")
def get_labels():
    return {
        "total":  len(labels),
        "labels": {str(i): l for i, l in enumerate(labels)}
    }

# ── Hot Reload ────────────────────────────────────────────────────────────
@app.post("/reload")
def reload_model():
    global interpreter, input_details, output_details, labels
    try:
        interpreter = tflite.Interpreter(model_path=MODEL_PATH)
        interpreter.allocate_tensors()
        input_details  = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        with open(LABELS_PATH, "r") as f:
            labels = [line.strip() for line in f if line.strip()]

        return {
            "status":  "reloaded",
            "classes": len(labels),
            "labels":  labels
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ── Health ────────────────────────────────────────────────────────────────
@app.get("/")
def home():
    return {
        "message":  "GesCom Backend is Running!",
        "model":    MODEL_PATH,
        "classes":  len(labels),
        "img_size": IMG_SIZE
    }