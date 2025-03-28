import datetime
from chatterbot import ChatBot
from chatterbot.trainers import ListTrainer
import re

# Function remove_chat_metadata()
#   @param chat_export_file: Dirección del fichero a tratar
#   @Def:
#   Elimina todos los metadatos asociados a cada una de las intervenciones en el registro
#   aportado para llevar a cabo el aprendizaje de chatterbot.
#*******************************************************************************************
def remove_chat_metadata(chat_export_file):
    date_time = r"(\d+\/\d+\/\d+\s\d+:\d+)"  # e.g. "9/16/22 06:34"
    dash_whitespace = r"\s-\s"  # " - "
    username = r"([\w\s]+)"  # e.g. "Martin"
    metadata_end = r":\s"  # ": "
    pattern = date_time + dash_whitespace + username + metadata_end
    with open(chat_export_file, "r") as corpus_file:
        content = corpus_file.read()
    cleaned_corpus = re.sub(pattern, "", content)

    return tuple(cleaned_corpus.split("\n"))



# Function remove_non_message_text()
#   @param chat_export_file: Dirección del fichero a tratar
#   @Def:
#   Elimina todas las intervenciones no deseadas en el registro aportado para llevar a cabo 
#   el aprendizaje de chatterbot. 
#*******************************************************************************************
def remove_non_message_text(export_text_lines):
    messages = export_text_lines[1:-1]

    filter_out_msgs = ("<Media omitted>",)
    filter_out_msgs = ("<Multimedia omitido>",)
    return tuple((msg for msg in messages if msg not in filter_out_msgs))



# Function printCleanChat()
#   @Def:
#   Imprime en la dirección indicada como parámetro el contenido del fichero previamente limpiado
#*******************************************************************************************
def printCleanChat (chatClean, sourceFile):
    for element in chatClean:
        print(f"{element}\n", file=sourceFile)   
    return



# Function chatbot_Init()
#   @Def:
#   Crea el chatbot, realiza el aprendizaje en base a los registros aportados e inicia el
#   chat del mismo con el usuario.
#*******************************************************************************************
def chatbot_Init():

    now = datetime.datetime.now()     
   
    #Chat 1 referencias (chico joven estudiante)
    chatURL = "chatWhatshap1.txt"
    dbPath = "sqlite:///chatWhatshap1.sqlite3"
    fileLog_url = f"../logsChatterbot/logWhatssap1_{now.year}-{now.month}-{now.day}_{now.hour}:{now.minute}:{now.second}.log"

    #Chat 2 referencias (mujer adulta trabajadora)
    #chatURL = "chatWhatshap2.txt"
    #dbPath = "sqlite:///chatWhatshap2.sqlite3"
    #fileLog_url = f"../logsChatterbot/logWhatssap2_{now.year}-{now.month}-{now.day}_{now.hour}:{now.minute}:{now.second}.log"

    sourceFile = open(fileLog_url, 'w+')
    chatClean = remove_chat_metadata(chatURL)
    chatClean = remove_non_message_text(chatClean)

    chatbot = ChatBot("Chatpot", database_uri=dbPath)
    trainer = ListTrainer(chatbot)
    trainer.train(chatClean)
    exit_conditions = (":q", "quit", "exit", "adios", "chao", "hasta luego", "bye")


    while True:
            query = input("> ")
            print('> ',query, file=sourceFile) 
            if query in exit_conditions:
                break;
            else:
                response = chatbot.get_response(query)
                print(f"{response}")
                print(f"{response}\n", file=sourceFile)           # Imprimimos la respuesta de Eliza en el log

    return


if __name__ == "__main__":
    chatbot_Init()