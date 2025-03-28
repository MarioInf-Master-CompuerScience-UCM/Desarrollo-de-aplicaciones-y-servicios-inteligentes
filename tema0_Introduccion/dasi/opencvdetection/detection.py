import cv2
import numpy as np
from PIL import Image
from keras import models
import os
import tensorflow as tf
from glob import glob

# checkpoint_path = "training_gender/cp.ckpt"
# checkpoint_dir = os.path.dirname(checkpoint_path)


class_names = glob("dataset/train/*") # Reads all the folders in which images are present
class_names = sorted(class_names) # Sorting them
name_id_map = dict(zip(class_names, range(len(class_names))))

model = models.load_model('model/model.h5')
# model.load_weights(tf.train.latest_checkpoint(checkpoint_dir))
video = cv2.VideoCapture(0)

while True:
        _, frame = video.read()

        #Convert the captured frame into RGB
        im = Image.fromarray(frame, 'RGB')

        #Resizing into dimensions you used while training
        im = im.resize((348,348))
        img_array = np.array(im)

        #Expand dimensions to match the 4D Tensor shape.
        img_array = np.expand_dims(img_array, axis=0)

        #Calling the predict function using keras
        prediction = model.predict(img_array)#[0][0]
        print(np.argmax(prediction, axis=1))

        #Customize this part to your liking...
        # if(prediction == 1 or prediction == 0):
        #     print("No Human")
        # elif(prediction < 0.5 and prediction != 0):
        #     print("Female")
        # elif(prediction > 0.5 and prediction != 1):
        #     print("Male")

        cv2.imshow("Prediction", frame)
        key=cv2.waitKey(1)
        if key == ord('q'):
                break
video.release()
cv2.destroyAllWindows()