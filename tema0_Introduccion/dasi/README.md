## Reconocimiento de frutas con redes neuronales
Cada miembreo del equipo va a entrenar su propio modelo y validarlo contra un conjunto de datos común con el objetivo de conseguir la mejor tasa de acierto del modelo sobre el conjunto de datos propuesto.

Para ello hemos elegido un dataset con 5 frutas, siendo estas: aguacate, kiwi, limon, naranja y piña.
También se han escogido imagenes fuera del dataset de entrenamiento para validar nuestros modelos, 10 por cada tipo.

## Parámetros de evaluación del modelo
```
loss: 0.2621
val_loss: 0.1863

accuracy: 0.9026 
val_accuracy: 0.9625
```

### Classification Report Validation
```
              precision    recall  f1-score   support

    aguacate       0.88      0.94      0.91        16
        kiwi       1.00      1.00      1.00        16
       limon       1.00      1.00      1.00        16
     naranja       1.00      1.00      1.00        16
        piña       0.93      0.88      0.90        16

    accuracy                           0.96        80
   macro avg       0.96      0.96      0.96        80
weighted avg       0.96      0.96      0.96        80
```

## Tasa de acierto de cada modelo

### Classification Report Testing
```
              precision    recall  f1-score   support

    aguacate       0.67      0.40      0.50        10
        kiwi       1.00      0.70      0.82        10
       limon       1.00      0.90      0.95        10
     naranja       1.00      1.00      1.00        10
        piña       0.50      0.90      0.64        10

    accuracy                           0.78        50
   macro avg       0.83      0.78      0.78        50
weighted avg       0.83      0.78      0.78        50
```


# Entorno

Las pruebas, entrenamiento y conclusiones del modelo se han realizado en Windows.

**Versión de python**
Para evitar conflictos entre versiones es necesaria la versión 3.7.9 de Python.
Para Windows se puede descargar aquí: https://www.python.org/ftp/python/3.7.9/python-3.7.9-amd64.exe

## Pasos para replicar el entorno de desarrollo
1. Clonar repositorio
2. Dentro de la carpeta del repositorio **crear entorno virtual**
`python -m venv venvdasi`
3. Activar entorno Virtual
`.\venvdasi\Scripts\activate`
4. Instalar prerequisitos
`pip install -r requirements.txt`
5. Lanzar jupyter
`jupyter notebook`

## Enlaces
https://frogames.es/la-guia-definitiva-de-las-redes-neuronales-convolucionales/

