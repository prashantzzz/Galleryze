import os, time, json
import tensorflow as tf
import numpy as np
from PIL import Image

# ----------------------------
# File paths
# ----------------------------
DETECTION_MODEL_PATH = '/content/sample_data/ssd_mobilenet_v2_coco_quantized.tflite'
CLASSIFIER_MODEL_PATH = '/content/sample_data/mobilenet_v2_imagenet_quantized.tflite'
MAPPING_JSON_PATH = '/content/sample_data/CategorizedClasses.json'
CATEGORIZED_JSON_PATH = os.path.join('/content/sample_data', "categorized.json")  # Folder for output JSON
CHECKPOINT_PATH = os.path.join('/content/sample_data/', "last_processed.txt")       # Checkpoint file

# ----------------------------
# Load the JSON mapping file
# ----------------------------
with open(MAPPING_JSON_PATH, 'r') as f:
    mapping_dict = json.load(f)
for key in mapping_dict:
    mapping_dict[key] = [s.lower() for s in mapping_dict[key]]

# ----------------------------
# Load TFLite models
# ----------------------------
detector = tf.lite.Interpreter(model_path=DETECTION_MODEL_PATH)
detector.allocate_tensors()

classifier = tf.lite.Interpreter(model_path=CLASSIFIER_MODEL_PATH)
classifier.allocate_tensors()

# For detection, load the COCO labels (assumed one label per line)
with open('/content/sample_data/coco-labels.txt', 'r') as f:
    coco_labels = [line.strip().lower() for line in f.readlines()]

# ----------------------------
# Preprocessing functions
# ----------------------------
def preprocess_image_for_detector(image, input_size):
    image = image.resize(input_size, Image.Resampling.LANCZOS)
    img_array = np.array(image)
    return np.expand_dims(img_array, axis=0).astype(np.uint8)

def preprocess_image_for_classifier(image, target_size=(224, 224)):
    image = image.resize(target_size, Image.Resampling.LANCZOS)
    img_array = tf.keras.preprocessing.image.img_to_array(image)
    img_array = np.expand_dims(img_array, axis=0)
    return tf.keras.applications.mobilenet_v2.preprocess_input(img_array)

# ----------------------------
# Helper function: mapping prediction to category
# ----------------------------
def map_prediction_to_category(pred_label, mapping):
    pred_label = pred_label.lower()
    for category, keywords in mapping.items():
        if pred_label in keywords:
            return category
    return 'Others'

# ----------------------------
# Hybrid pipeline function (original approach)
# ----------------------------
def hybrid_pipeline(image_path, confidence_threshold=0.35):
    image = Image.open(image_path).convert('RGB')

    # --- Step 1: Run the detector ---
    det_input_details = detector.get_input_details()
    det_output_details = detector.get_output_details()
    det_input_size = (det_input_details[0]['shape'][1], det_input_details[0]['shape'][2])

    det_input = preprocess_image_for_detector(image, det_input_size)
    detector.set_tensor(det_input_details[0]['index'], det_input)
    detector.invoke()

    boxes = detector.get_tensor(det_output_details[0]['index'])[0]
    class_ids = detector.get_tensor(det_output_details[1]['index'])[0]
    scores = detector.get_tensor(det_output_details[2]['index'])[0]

    for i, score in enumerate(scores):
        if score >= confidence_threshold:
            detected_label = coco_labels[int(class_ids[i])].lower()
            # If detected label belongs to "Docs" or "People", immediately return those fixed categories
            if detected_label in mapping_dict.get("Docs", []):
                return "Docs"
            if detected_label in mapping_dict.get("People", []):
                return "People"

    # --- Step 2: Run the classifier ---
    cls_input_details = classifier.get_input_details()
    cls_output_details = classifier.get_output_details()
    cls_input_size = (cls_input_details[0]['shape'][1], cls_input_details[0]['shape'][2])

    cls_input = preprocess_image_for_classifier(image, target_size=cls_input_size)
    classifier.set_tensor(cls_input_details[0]['index'], cls_input)
    classifier.invoke()

    preds = classifier.get_tensor(cls_output_details[0]['index'])
    decoded = tf.keras.applications.mobilenet_v2.decode_predictions(preds, top=1)
    predicted_desc = decoded[0][0][1]
    return map_prediction_to_category(predicted_desc, mapping_dict)

# ----------------------------
# Batch processing for folder with checkpointing
# ----------------------------
def process_folder(folder_path, confidence_threshold=0.35):
    supported_formats = (".jpg", ".jpeg", ".png", ".bmp", ".gif")

    # Load existing categorized data, if available
    if os.path.exists(CATEGORIZED_JSON_PATH):
        with open(CATEGORIZED_JSON_PATH, "r") as json_file:
            categorized_data = json.load(json_file)
    else:
        categorized_data = {"Docs": [], "People": [], "Animal": [], "Nature": [], "Food": [], "Others": []}

    # Load checkpoint timestamp if exists
    last_timestamp = 0
    if os.path.exists(CHECKPOINT_PATH):
        with open(CHECKPOINT_PATH, 'r') as f:
            try:
                last_timestamp = float(f.read().strip())
            except ValueError:
                last_timestamp = 0

    # Get all image files with their full paths and modification times
    image_files = [
        (f, os.path.getmtime(os.path.join(folder_path, f)))
        for f in sorted(os.listdir(folder_path))
        if f.lower().endswith(supported_formats)
    ]

    new_last_timestamp = last_timestamp
    for image_file, mod_time in image_files:
        if mod_time <= last_timestamp:
            continue  # Skip already processed files

        image_path = os.path.join(folder_path, image_file)
        category = hybrid_pipeline(image_path, confidence_threshold)
        categorized_data[category].append(image_path)
        print(f"Processed: {image_file} -> Category: {category}")

        # Update the most recent timestamp
        if mod_time > new_last_timestamp:
            new_last_timestamp = mod_time

    # Save updated categorized data
    with open(CATEGORIZED_JSON_PATH, "w") as json_file:
        json.dump(categorized_data, json_file, indent=4)
    print(f"Categorized data saved to: {CATEGORIZED_JSON_PATH}")

    # Update checkpoint with latest timestamp
    if new_last_timestamp > last_timestamp:
        with open(CHECKPOINT_PATH, 'w') as f:
            f.write(str(new_last_timestamp))
        print(f"Checkpoint updated to timestamp: {new_last_timestamp} ({time.ctime(new_last_timestamp)})")

# ----------------------------
# Example usage
# ----------------------------
if __name__ == "__main__":
    folder_path = '/content/test'  # Replace with your folder path containing images
    process_folder(folder_path, confidence_threshold=0.35)
