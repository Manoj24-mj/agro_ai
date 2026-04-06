import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator

IMG = 224

datagen = ImageDataGenerator(rescale=1./255, validation_split=0.2)

train = datagen.flow_from_directory(
    "dataset/",
    target_size=(IMG, IMG),
    subset="training"
)

val = datagen.flow_from_directory(
    "dataset/",
    target_size=(IMG, IMG),
    subset="validation"
)

base = tf.keras.applications.MobileNetV2(
    input_shape=(224,224,3),
    include_top=False,
    weights='imagenet'
)

x = tf.keras.layers.GlobalAveragePooling2D()(base.output)
x = tf.keras.layers.Dense(128, activation='relu')(x)
out = tf.keras.layers.Dense(train.num_classes, activation='softmax')(x)

model = tf.keras.Model(inputs=base.input, outputs=out)

model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
model.fit(train, validation_data=val, epochs=10)

model.save("plant_model.h5")