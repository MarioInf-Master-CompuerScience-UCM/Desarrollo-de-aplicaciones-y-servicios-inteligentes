    #def getURLbyID(self, IDlist):
from datetime import date
import sys
import pandas as pd


#******************************************************************************
#FUNCION MAIN
#******************************************************************************
if __name__=="__main__":
    if len(sys.argv) == 2:
        urlFile = sys.argv[1]
    else:
        print("ERROR: Faltan parámetros de entrada.", file=sys.stderr);
        print("\n>> VectorialIndex \"nombreArchivoCSV\"", file=sys.stderr);
        exit;


    dataWorld = pd.read_csv(urlFile)
    dataSpain = dataWorld[dataWorld["location"]== "Spain"]
    
    dataSpain["new_cases_smoothed"].fillna(0)
    dataSpain["total_deaths"].fillna(0)
    dataSpain["new_deaths"].fillna(0)
    dataSpain["new_deaths_smoothed"].fillna(0)

    dataSpain['date'] = pd.to_datetime(dataSpain['date'], errors = 'coerce')
    dataSpain.dropna(subset=['date'], inplace = True)
    
    dataSpain.to_csv("result.csv")






""" 
partir de este DataFrame crea otro que tenga solo los datos de España

Limpiar el DataFrame resultante haciendo varios ajustes:
    En las columnas new_cases_smoothed, total_deaths, new_deaths y
    new_deaths_smoothed, poner a 0 las celdas vacías

    Poner como objetos tipo date las celdas de la columna date

    Sacar un listado de las filas donde el número de casos (new_cases) sea negativo

    Comprobar si hay filas duplicadas y si las hubiera, eliminarlas

    Guardar el resultado en un fichero excel

Guardar el resultado en un fichero Excel y comprobar que está bien
"""



