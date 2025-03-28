import logging
import random
import re
from collections import namedtuple
import datetime

'''
# DIAGRAMA DE FLUJO RESUMIDO

    MAIN(){
        Eliza eliza;
        eliza.load(){ }

        eliza.run(){
            open(fileLog_url)
            print(initial())    

            while(1){
                sent = input()
                output = respond(sent){
                    _sub(sent, pres){ }

                    for key in keys{
                        _match_key(words, key){
                        
                            _match_decomp(self, parts, words){
                                _match_decomp_r(self, parts, words, results){ *Recursividad* }
                            }

                            _sub(words, self.posts){ }
                            _next_reasmb(decomp){ }
                        }
                    
                    }
                }
                print(output)
            }
            
            print(final())
            close(fileLog_url)
        }
    }
'''

# Fix Python2/Python3 incompatibility
try: input = input
except NameError: pass

log = logging.getLogger(__name__)

#*********************************************************************
#*************************  START KEY CLASS  *************************
#*********************************************************************
class Key:
    def __init__(self, word, weight, decomps):
        self.word = word                # Palabra clave
        self.weight = weight            # Peso de la palabra ustilziado para elegir las respuestas de Eliza
        self.decomps = decomps          # Conjuntos de posibles respusatas asociadas a la palabra clave



#*********************************************************************
#***********************  START DECOMP CLASS  ************************
#*********************************************************************
class Decomp:
    def __init__(self, parts, save, reasmbs):
        self.parts = parts             # Palabras que forman la estructura morfológica que identifica a la palabra clave dicha por el usuario
        self.save = save
        self.reasmbs = reasmbs
        self.next_reasmb_index = 0
        
        

#*********************************************************************
#************************  START ELIZA CLASS  ************************
#*********************************************************************
class Eliza:
    def __init__(self):
        self.initials = []          # Array con las respuestas de Eliza cuando se inicia el programa
        self.finals = []            # Array con las respuestas de Eliza cuando se finaliza el programa
        self.quits = []             # Array con las respuestas del usuario que indican que se quiere finalizar el programa
        self.pres = {}              # Diccionario de palabras que pueden escribirse morfologicamente de diferentes maneras. La clave es la palabra base y el contenido una lista con cada una de sus posibes morfologías.
        self.posts = {}
        self.synons = {}            # Diccionario de palabras tratadas como sinonimos
        self.keys = {}              # Diccionario con las palabras clave dichas por el usuario, ls cuales usaremos para crear las respuestas de Eliza
        self.memory = []            # Array donde se almacenan las distintas expresiones dichas por Eliza cuya descomposición contiene el caracter especial $S


    # Function load()
    #   @param path: Localizacion del archivo de configruación del lenguaje natural
    #   @Def:
    #   Accede al fichero de configuración del lengiaje natural y clasifica la información del mismo
    #   en base en los diferentes atributos de la clase según las claves utilziadas.
    #***********************************************************************************************
    def load(self, path):
        key = None
        decomp = None
        with open(path) as file:                    # Accedemos al fichero de configuración del lenguaje natural
            for line in file:                       # Realziamos la elctura linea a linea
                if not line.strip():                # Limpiamos la información de la linea eliminando caracteres innecesarios
                    continue
                tag, content = [part.strip() for part in line.split(':')]   # Separamos la clave del conenido y limpiamos ambos

                if tag == 'initial':                # Clasificación de las respuestas iniciales
                    self.initials.append(content)       # Añadimos el contenido al array de respuestas de Eliza cuando se inicia el programa

                elif tag == 'final':                # Clasificación de las respuestas finales
                    self.finals.append(content)         # Añadimos el contenido al array de respuestas de Eliza cuando se finaliza el programa

                elif tag == 'quit':                 # Clasificación de las respuestas de salida
                    self.quits.append(content)          # Añadimos el contenido al array con las respuestas del usuario que indican que se quiere finalizar el programa

                elif tag == 'pre':                  # Clasificación de las palabras con varias posibilidades morfológicas.
                    parts = content.split(' ')          # Dividimos el contenido en una lista de palabras
                    self.pres[parts[0]] = parts[1:]     # Añadimos una nueva entrada al diccionario, utilizando como clave la primera palabra de la lista y como contenido el resto 

                elif tag == 'post':
                    parts = content.split(' ')
                    self.posts[parts[0]] = parts[1:]

                elif tag == 'synon':                # Clasificación de als palabras tratadas como sinónimos
                    parts = content.split(' ')          # Dividimos el contenido en una lista de palabras
                    self.synons[parts[0]] = parts       # Añadimos una nueva entrada al duccionario, tratando como clave la primera palabra de la lista y como contenido el resto

                elif tag == 'key':                  # Clasifiación de las palabras clave del usuario conforme a las cuales crearemos la respuesta de Eliza
                    parts = content.split(' ')          # Dividimos el contenido en una lista de palabras
                    word = parts[0]                     # Utilizamos la primera palabra como clave
                    weight = int(parts[1]) if len(parts) > 1 else 1 # Obtenemos numero indicado como segundo parámetro
                    key = Key(word, weight, [])         # Creamos una clave con los valores obtenidos anteriormente
                    self.keys[word] = key               # Introducimos la clave al diccionario de palabras clave dicahs por el usuario

                elif tag == 'decomp':                   # Clasificamos la morfología que identifica a la palabra clave
                    parts = content.split(' ')              # Dividimos la expresión que identifica la morfología en una lista de palabras
                    save = False
                    if parts[0] == '$':                     # Identificamos el paŕametro especial $ al inicio de la expresión
                        save = True
                        parts = parts[1:]
                    decomp = Decomp(parts, save, [])        # Creamos una descomposición con los valores obtenidos anteriormente
                    key.decomps.append(decomp)              # Introducimos la descomposición

                elif tag == 'reasmb':                       # Clasificamos las posibles respuestas a una palabra clave dicha por el usuario
                    parts = content.split(' ')                  # Dividimos la respuesta en una lista de palabras
                    decomp.reasmbs.append(parts)                # Introducimos la respuesta en la descomposición corresponsiente
        return;


    # Function _match_decomp_r(self, parts, words, results)
    #   @pram parts: Descomposición morfolígica de la palabra clave a comprobar
    #   @param words: Array con las palabras a analizar.
    #   @Def:
    #   Comprobamos si el array de palabras introducidas contiene la descomposición mrofológica que identifica a la palabra clave
    #***********************************************************************************************
    def _match_decomp_r(self, parts, words, results):
        if not parts and not words:                         # Si no hay palabras ni en el array ni en la descomposicón morfológica se trata como coincidencia
            return True
        

        if not parts or (not words and parts != ['*']):     # Si no hay palabras en la descomposición o hay palabras en el array y la descomposición contiene alguna plabra distinta del comodin, se trata como no coincidencia
            return False
        

        if parts[0] == '*':                                 # Si la palabra en la descomposición es el caracter comodin (*)
            for index in range(len(words), -1, -1):             # Se recorren todas las palabras del array
                results.append(words[:index])                   # Se introduce la descomposición del array en los resultados
                if self._match_decomp_r(parts[1:], words[index:], results):     #Comprobación recursiva de los resultados
                    return True                                 # Si alguna de las descomposisiciones des array coincide con la descomposición de la palabra clave, se trata como coincidencia
                results.pop()
            return False                                        # Sino, se elimina la descomposición de los resultado y se trata como no coincidencia.
        

        elif parts[0].startswith('@'):                      # Si la palabra comienza con el caracter sinomimo (@)
            root = parts[0][1:]                             
            if not root in self.synons:                         # Si el formato no es correcto, se lanza un error
                raise ValueError("Unknown synonym root {}".format(root))
            if not words[0].lower() in self.synons[root]:       
                return False                                    # Si la palabra no se encuentra en la lista de sinonimos, se trata como no coincidencia
            results.append([words[0]])                          # Sino, se introduce la palabra en los rsultados
            return self._match_decomp_r(parts[1:], words[1:], results)       #Comprobación recursiva de los resultados
        

        elif parts[0].lower() != words[0].lower():              # Caso Base, si la primera palabra del araay no coincide con al primera palabra de la descomposición, se trata como no coincidencia   
            return False
        

        else:
            return self._match_decomp_r(parts[1:], words[1:], results)      # Si la primera palabra del array y de la descomposición coincide, se com prueban recursivamente las segundas


    # Function _match_decomp(self, parts, words)
    #   @pram parts: Descomposición morfolígica de la palabra clave a comprobar
    #   @param words: Array con las palabras a analizar.
    #   @Def:
    #   Retornamos los resultados de la comprobación entre el array de palabras y la morfología que identificala palabra clave
    #***********************************************************************************************
    def _match_decomp(self, parts, words):
        results = []
        if self._match_decomp_r(parts, words, results):
            return results
        return None


    # Function _next_reasmb(decomp)
    #   @Param decomp: Descomposición de la palabra clave correspondiente
    #   @Def:
    #   Retornamos la siguiente respuesta a la palabra clave indicada como parámetro con el fin de evitar redundancias
    #   En las respuestas de Eliza
    #***********************************************************************************************
    def _next_reasmb(self, decomp):
        index = decomp.next_reasmb_index
        if len(decomp.reasmbs) > 0:
            result = decomp.reasmbs[index % len(decomp.reasmbs)]
        else:
            result = decomp.reasmbs[0]
        decomp.next_reasmb_index = index + 1
        return result


    # Function _reassemble()
    #***********************************************************************************************
    def _reassemble(self, reasmb, results):
        output = []
        for reword in reasmb:
            if not reword:
                continue
            if reword[0] == '(' and reword[-1] == ')':
                index = int(reword[1:-1])
                if index < 1 or index > len(results):
                    raise ValueError("Invalid result index {}".format(index))
                insert = results[index - 1]
                for punct in [',', '.', ';']:
                    if punct in insert:
                        insert = insert[:insert.index(punct)]
                output.extend(insert)
            else:
                output.append(reword)
        return output


    # Function _sub(words, sub)
    #   @param words: Array con las palabras a analizar.
    #   @pram sub: Diccionario que contiene como clave la palabra base y como contenido cada una de sus variantes morfológicas.
    #   @Def:
    #   Introduce en la lista de palabras aportada como parámetro, las posibles viriantes morfoógicas de las mismas según el
    #   diccionario indicado.
    #***********************************************************************************************
    def _sub(self, words, sub):
        output = [] 
        for word in words:                      # Recorremos la lista con todas las palabras introducidas por el usuario
            word_lower = word.lower()           
            if word_lower in sub:               # Si la palabra coincide con una clave del diccionario:
                output.extend(sub[word_lower])      # Introducimos el contenido de dicha clave en el array de retorno.
            else:                               # Sino:
                output.append(word)                 # Introducimos la palabra en el array de retorno.
        return output


    # Function _match_key()
    #***********************************************************************************************
    def _match_key(self, words, key):

        for decomp in key.decomps:                                      # Recorremos el array de descomposiciones morfológicas asociadas a la clave
            results = self._match_decomp(decomp.parts, words)           # Comprobamos si la descomposición de la clave se encuentra en la lista de palabras
            if results is None:                                         # Sino, se pasa a al siguiente descomposición de la plabra clave
                log.debug('Decomp did not match: %s', decomp.parts)
                continue

            log.debug('Decomp matched: %s', decomp.parts)
            log.debug('Decomp results: %s', results)
            
            results = [self._sub(words, self.posts) for words in results]   # Buscamos que palabras devuelatas como resultado tienen varias posibilidades morfológicas e introducimos cada una de ellas en el array de resultados.
            log.debug('Decomp results after posts: %s', results)
            
            reasmb = self._next_reasmb(decomp)              # Accedemos a una de las posibles respuestas a la palabra clave encontrada
            log.debug('Using reassembly: %s', reasmb)
            if reasmb[0] == 'goto':                         # En el caso de que la respuesta comience por la palabra goto debremos realizar un salta a la palabra clave indicada por la segunda palabra
                goto_key = reasmb[1]                            # Identificamos la palabra clave a la que deberemos saltar
                if not goto_key in self.keys:                   # Si la palabra clave no existe se mostrará un error
                    raise ValueError("Invalid goto key {}".format(goto_key))
                log.debug('Goto key: %s', goto_key)
                return self._match_key(words, self.keys[goto_key])  # Llamada recursiva para elegir el resultado de la palabra clave referenciada por le goto
            output = self._reassemble(reasmb, results)              # Se ensambla el resultado a decir por Eliza
            if decomp.save:                                 # Si la descomposición empezaba por el caracter especial $, se almacenará la misma en le array de memoria
                self.memory.append(output)
                log.debug('Saved to memory: %s', output)
                continue
            return output                                   # Retornamos la expresion ensamblada como resultado
        return None


    # Function respond(text)
    #   @param text: Petición realizada por el usuario
    #   @Def:
    #   Se calcula la respuesta de Eliza en función de la patición realizada pr el usuario
    #***********************************************************************************************
    def respond(self, text):
        if text.lower() in self.quits:                      # Comprobamos si el usuario ha introducido una respuesta de finalización.
            return None
        
        text = re.sub(r'\s*\.+\s*', ' . ', text)            # Introducimos espacios entre los puntos (.) y el resto de caracteres.
        text = re.sub(r'\s*,+\s*', ' , ', text)             # Introducimos espacios entre las comas (,) y el resto de caracteres.
        text = re.sub(r'\s*;+\s*', ' ; ', text)             # Introducimos espacios entre los punto y coma (;) y el resto de caracteres.
        log.debug('After punctuation cleanup: %s', text)

        words = [w for w in text.split(' ') if w]           # Creamos un array con las palablas que conforma la petición del usuario.
        log.debug('Input: %s', words)

        words = self._sub(words, self.pres)                 # Buscamos las palabras que ha dicho el usuario con varias posibilidades morfológicas e introducimos cada una de ellas en el array.
        log.debug('After pre-substitution: %s', words)

        keys = [self.keys[w.lower()] for w in words if w.lower() in self.keys]  # Buscamos las palabras clave que ha escrito el usuario y las introducimos en un array.
        keys = sorted(keys, key=lambda k: -k.weight)                            # Ordenamos el array de claves en base al peso asociado a las mismas
        log.debug('Sorted keys: %s', [(k.word, k.weight) for k in keys])
        output = None

        for key in keys:                                    # Recorremos el array de palabras clave dichas por el usuario ordenadas por peso
            output = self._match_key(words, key)            # Obtenemos la respuesta de Eliza a la petición del usuario   
            if output:
                log.debug('Output from key: %s', output)
                break
    
        if not output:                                      # Si la respuesta obtenida es None
            if self.memory:                                     # Si el array de memoria no esta vacio
                index = random.randrange(len(self.memory))          # Seleccionamos una de las respuestas guadads en la memoria
                output = self.memory.pop(index)                     # Guardamos la respuesta seleccionada como saldia de eliza y la eliminamos el array
                log.debug('Output from memory: %s', output)
            else:                                           # Sino, seleccionamos una de las respuestas del conjunto destinado a no haber entendido al usuario
                output = self._next_reasmb(self.keys['xnone'].decomps[0])
                log.debug('Output from xnone: %s', output)

        return " ".join(output)                             # Retornamos la respuesta de Eliza


    # Function initial()
    #   @Def:
    #   Selecciona una respuesta aleatoria de todas las posibles dentro con las respuestas de Eliza
    #   cuando se inicia el programa.
    #***********************************************************************************************
    def initial(self):
        return random.choice(self.initials)


    # Function final()
    #   @Def:
    #   Selecciona una respuesta aleatoria de todas las posibles dentro con las respuestas de Eliza
    #   cuando se finaliza el programa.
    #***********************************************************************************************
    def final(self):
        return random.choice(self.finals)


    # Function run()
    #   @Def:
    #   Interfaz de interacción entre el usuario y el sistema de lenguaje natural de Elzia.
    #***********************************************************************************************
    def run(self):
        now = datetime.datetime.now()  
        fileLog_url = f"logsEliza/logEliza_{now.year}-{now.month}-{now.day}_{now.hour}:{now.minute}:{now.second}.log"
        print("Esta conversaición será guardada en el log:", fileLog_url)
        sourceFile = open(fileLog_url, 'w+')                # Generamos el fichero para almacenar los logs
        print(self.initial())                               # Generamos la respuesta inicial de Eliza
        print(f"{self.initial()}\n", file=sourceFile)

        while True:
            sent = input('> ')                              # El usuario introduce su petición por el teclado
            print('> ',sent, file=sourceFile)               # Almacenamos la petición dle usuario en el log

            output = self.respond(sent)

            print(output)                                   # Imprimimos la respuesta de Eliza a la petición dle usuario
            print(f"{output}\n", file=sourceFile)           # Imprimimos la respuesta de Eliza en el log

            if output is None:                              # Si el usuario ha introducido una secuencia de finalización, el bucle finaliza
                break
        
        print(self.final())                                 # Generamos la respuesta final de Eliza
        print(self.final(),"\n\n", file=sourceFile)
        sourceFile.close();



#*********************************************************************
#***************************  START MAIN  ****************************
#*********************************************************************
def main():

    eliza = Eliza()
    eliza.load('doctor.txt')
    eliza.run()


if __name__ == '__main__':
    logging.basicConfig()
    main()
