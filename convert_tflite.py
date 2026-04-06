import tensorflow as tf

# Convert the model
model = tf.keras.models.load_model('plant_model.h5')
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the model
with open('plant_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Model successfully converted to plant_model.tflite")