from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import pipeline
from PIL import Image
from io import BytesIO
import requests

app = FastAPI()

classifier = pipeline(
    "zero-shot-image-classification",
    model="openai/clip-vit-base-patch32"
)

PET_LABELS = [
    "cat",
    "dog",
    "bird",
    "rabbit",
    "hamster",
    "guinea pig",
    "fish",
    "turtle",
    "pet animal"
]

NON_PET_LABELS = [
    "human",
    "food",
    "car",
    "building",
    "landscape",
    "clothing",
    "furniture",
    "text screenshot",
    "random object"
]

class DetectRequest(BaseModel):
    image_url: str

@app.get("/")
def home():
    return {"status": "Pet ML API running"}

@app.post("/detect-pet")
def detect_pet(data: DetectRequest):
    try:
        image_response = requests.get(data.image_url, timeout=20)

        if image_response.status_code != 200:
            raise HTTPException(status_code=400, detail="Could not fetch image")

        image = Image.open(BytesIO(image_response.content)).convert("RGB")

        labels = PET_LABELS + NON_PET_LABELS

        results = classifier(
            image,
            candidate_labels=labels,
            hypothesis_template="This is a photo of a {}."
        )

        top_result = results[0]
        label = top_result["label"]
        confidence = float(top_result["score"])

        is_pet = label in PET_LABELS and confidence >= 0.45

        return {
            "is_pet": is_pet,
            "confidence": round(confidence, 4),
            "label": label,
            "top_results": results[:5]
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))