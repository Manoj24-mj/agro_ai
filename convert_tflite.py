import tensorflow as tf

# Load the existing Keras model
model = tf.keras.models.load_model('plant_model.h5')

# Create the converter
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Apply optimizations (Dynamic range quantization)
# This reduces the model size and speeds up inference on mobile devices
converter.optimizations = [tf.lite.Optimize.DEFAULT]

# Convert the model
tflite_model = converter.convert()

# Save the optimized model
with open('plant_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Optimized model successfully converted to plant_model.tflite")