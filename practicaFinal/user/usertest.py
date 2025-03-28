import numpy as np
from PIL import Image
from keras import models
import os
import shutil

filepath = './images/'

classes = ['aguacate', 'kiwi', 'limon', 'naranja', 'piña']
model = models.load_model('../model/modelfinal.h5')

def get_class(filename):
    return filename.split('_')[0]

correct = 0
error = 0
total = len(os.listdir(filepath))

for filename in os.listdir(filepath):
    with open(f'./exception/exception.log', "a") as log:
        try:
            path = filepath + filename

            img = Image.open(path)
            img = img.resize((348, 348))
            img_array = np.array(img)
            img_array = np.expand_dims(img_array, axis=0)

            prediction = classes[np.argmax(model(img_array), axis=1)[0]]
            expected = get_class(filename)

            if prediction == expected:
                correct += 1
                print(f'Predicción correcta: {prediction}')          
                # shutil.move(path, f'./clasified/{filename}')
            else:
                print(f'Fallo en la predicción: predicción {prediction} - esperado {expected}')
                # shutil.move(path, f'./wrong/{filename}')
            
            index = 0

        except Exception as e:
            error += 1
            print(f'{e}')

            log.write(f'{e}\n')      
            log.write(f'Error in {filename}\n\n')
            # shutil.move(path, f'./exception/{filename}')

print(f'\nResultados (totales = {total}):')
print(f' - Aciertos: {correct} ({"{:.2f}".format(100*correct/total)} %)')
print(f' - Fallos: {(total-correct)} ({"{:.2f}".format(100*(total-correct)/total)} %)')
print(f' - Excepciones: {error} ({"{:.2f}".format(100*error/total)} %)')
